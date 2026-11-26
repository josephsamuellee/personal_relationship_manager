import { Controller } from "@hotwired/stimulus"
import {
  buildSnapshot,
  nextBackoffMs,
  snapshotsEqual,
  statusLabel
} from "entry_draft_autosave_helpers"

const DEBOUNCE_MS = 3000

function newClientCreateId() {
  if (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function") {
    return crypto.randomUUID()
  }
  return `draft-${Date.now()}-${Math.random().toString(16).slice(2)}`
}

export default class extends Controller {
  static targets = ["status", "conflictPanel", "localCopy", "lockVersion"]
  static values = {
    createUrl: String,
    draftId: { type: Number, default: 0 },
    entryId: { type: Number, default: 0 },
    lockVersion: { type: Number, default: 0 },
    clientCreateId: { type: String, default: "" },
    updateUrlTemplate: { type: String, default: "/entry_drafts/:id" },
    editUrlTemplate: { type: String, default: "/entry_drafts/:id/edit" }
  }

  connect() {
    this.lastAckedSnapshot = this.readSnapshot()
    this.pendingSnapshot = null
    this.inFlight = false
    this.createInFlight = false
    this.retryAttempt = 0
    this.debounceTimer = null
    this.retryTimer = null
    this.conflicted = false
    this.gone = false
    this.serverConflictPayload = null
    this.boundBeforeUnload = this.handleBeforeUnload.bind(this)
    this.boundBeforeVisit = this.handleBeforeVisit.bind(this)
    this.boundInput = this.handleInput.bind(this)
    this.boundSubmit = this.handleSubmit.bind(this)

    if (!this.clientCreateIdValue) {
      this.clientCreateIdValue = newClientCreateId()
    }

    this.element.addEventListener("input", this.boundInput)
    this.element.addEventListener("change", this.boundInput)
    this.element.addEventListener("submit", this.boundSubmit)
    window.addEventListener("beforeunload", this.boundBeforeUnload)
    document.addEventListener("turbo:before-visit", this.boundBeforeVisit)

    if (this.draftIdValue > 0) {
      this.setStatus("saved")
    } else {
      this.setStatus("")
    }
  }

  disconnect() {
    this.clearTimers()
    this.element.removeEventListener("input", this.boundInput)
    this.element.removeEventListener("change", this.boundInput)
    this.element.removeEventListener("submit", this.boundSubmit)
    window.removeEventListener("beforeunload", this.boundBeforeUnload)
    document.removeEventListener("turbo:before-visit", this.boundBeforeVisit)
  }

  handleInput() {
    if (this.conflicted || this.gone) return

    const snapshot = this.readSnapshot()
    if (snapshotsEqual(snapshot, this.lastAckedSnapshot)) {
      this.pendingSnapshot = null
      this.clearTimers()
      if (this.draftIdValue > 0) this.setStatus("saved")
      else this.setStatus("")
      return
    }

    this.pendingSnapshot = snapshot
    this.setStatus("unsaved")
    this.scheduleDebouncedSave()
  }

  scheduleDebouncedSave() {
    if (this.conflicted || this.gone) return
    if (this.debounceTimer) clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => {
      this.debounceTimer = null
      this.saveNow()
    }, DEBOUNCE_MS)
  }

  handleSubmit() {
    this.clearTimers()
    if (this.conflicted || this.gone) return
    if (this.isDirty()) {
      this.saveNow({ force: true }).catch(() => {})
    }
  }

  handleBeforeUnload(event) {
    if (!this.isDirty()) return
    event.preventDefault()
    event.returnValue = ""
  }

  handleBeforeVisit(event) {
    if (!this.isDirty()) return
    const leave = window.confirm("You have unsaved draft changes. Leave this page?")
    if (!leave) {
      event.preventDefault()
      return
    }
    this.clearTimers()
    this.flushBeacon()
  }

  isDirty() {
    if (this.conflicted || this.gone) return false
    const current = this.readSnapshot()
    if (!snapshotsEqual(current, this.lastAckedSnapshot)) return true
    return this.pendingSnapshot != null && !snapshotsEqual(this.pendingSnapshot, this.lastAckedSnapshot)
  }

  readSnapshot() {
    return buildSnapshot({
      title: this.fieldValue('input[name="entry[title]"]'),
      rawDate: this.fieldValue('input[name="entry[raw_date]"]'),
      bodyMarkdown: this.bodyValue()
    })
  }

  fieldValue(selector) {
    const el = this.element.querySelector(selector)
    return el ? el.value : ""
  }

  bodyValue() {
    const editorRoot = this.element.querySelector(".markdown-editor-field")
    const textarea = editorRoot?.querySelector("textarea") || this.element.querySelector('textarea[name="entry[body_markdown]"]')
    return textarea ? textarea.value : ""
  }

  setBodyValue(value) {
    const editorRoot = this.element.querySelector(".markdown-editor-field")
    const controller = editorRoot
      ? this.application.getControllerForElementAndIdentifier(editorRoot, "markdown-editor")
      : null
    if (controller?.editor && typeof controller.editor.setValue === "function") {
      controller.editor.setValue(value)
      return
    }
    const textarea = editorRoot?.querySelector("textarea") || this.element.querySelector('textarea[name="entry[body_markdown]"]')
    if (textarea) {
      textarea.value = value
      textarea.dispatchEvent(new Event("input", { bubbles: true }))
    }
  }

  async saveNow({ force = false } = {}) {
    if (this.conflicted || this.gone) return

    const snapshot = this.pendingSnapshot || this.readSnapshot()
    if (!force && snapshotsEqual(snapshot, this.lastAckedSnapshot)) return
    if (this.inFlight) {
      this.pendingSnapshot = snapshot
      return
    }
    if (this.createInFlight && this.draftIdValue <= 0) {
      this.pendingSnapshot = snapshot
      return
    }

    this.inFlight = true
    if (this.draftIdValue <= 0) this.createInFlight = true
    this.setStatus("saving")

    try {
      const response = await this.sendSnapshot(snapshot)
      if (response.status === 409) {
        const data = await response.json()
        this.enterConflict(data, snapshot)
        return
      }
      if (response.status === 404 || response.status === 410) {
        this.enterGone()
        return
      }
      if (!response.ok) throw new Error(`autosave failed: ${response.status}`)
      const data = await response.json()
      this.applyAck(data, snapshot)
      this.retryAttempt = 0
      this.setStatus("saved")

      if (this.pendingSnapshot && !snapshotsEqual(this.pendingSnapshot, this.lastAckedSnapshot)) {
        const next = this.pendingSnapshot
        this.pendingSnapshot = null
        this.inFlight = false
        this.createInFlight = false
        this.pendingSnapshot = next
        await this.saveNow({ force: true })
        return
      }
    } catch (_error) {
      if (this.conflicted || this.gone) return
      this.pendingSnapshot = snapshot
      this.setStatus("retrying")
      this.scheduleRetry()
      throw _error
    } finally {
      this.inFlight = false
      this.createInFlight = false
    }
  }

  enterConflict(data, localSnapshot) {
    this.conflicted = true
    this.serverConflictPayload = data
    this.clearTimers()
    this.pendingSnapshot = null
    this.setStatus("conflict")
    if (this.hasLocalCopyTarget) {
      this.localCopyTarget.value = localSnapshot?.bodyMarkdown ?? this.bodyValue()
    }
    if (this.hasConflictPanelTarget) {
      this.conflictPanelTarget.hidden = false
    }
  }

  enterGone() {
    this.gone = true
    this.conflicted = false
    this.clearTimers()
    this.pendingSnapshot = null
    this.draftIdValue = 0
    this.lockVersionValue = 0
    const draftField = this.element.querySelector('input[name="entry[draft_id]"]')
    if (draftField) draftField.remove()
    this.setStatus("")
    if (this.hasConflictPanelTarget) this.conflictPanelTarget.hidden = true
  }

  reloadServerVersion(event) {
    event?.preventDefault()
    const data = this.serverConflictPayload
    if (!data) return

    const localBody = this.bodyValue()
    if (this.hasLocalCopyTarget) {
      this.localCopyTarget.value = localBody
    }

    const titleField = this.element.querySelector('input[name="entry[title]"]')
    const dateField = this.element.querySelector('input[name="entry[raw_date]"]')
    if (titleField && data.title != null) titleField.value = data.title
    if (dateField && data.raw_date != null) dateField.value = data.raw_date
    if (data.body_markdown != null) this.setBodyValue(data.body_markdown)

    this.applyAck(data, this.readSnapshot())
    this.conflicted = false
    this.serverConflictPayload = null
    this.setStatus("saved")
    if (this.hasConflictPanelTarget) {
      // Keep panel visible so local copy remains available after reload.
      this.conflictPanelTarget.hidden = false
    }
  }

  applyAck(data, snapshot) {
    if (data.id) {
      this.draftIdValue = data.id
      this.ensureDraftIdField(data.id)
      if (data.edit_url && this.entryIdValue <= 0) {
        const url = data.edit_url
        if (window.location.pathname !== url) {
          window.history.replaceState(window.history.state, "", url)
        }
      }
    }
    if (typeof data.lock_version === "number") {
      this.lockVersionValue = data.lock_version
      this.syncLockVersionField(data.lock_version)
    }
    if (data.client_create_id) {
      this.clientCreateIdValue = data.client_create_id
    }
    this.lastAckedSnapshot = snapshot
    this.pendingSnapshot = null
  }

  ensureDraftIdField(id) {
    let field = this.element.querySelector('input[name="entry[draft_id]"]')
    if (!field) {
      field = document.createElement("input")
      field.type = "hidden"
      field.name = "entry[draft_id]"
      this.element.appendChild(field)
    }
    field.value = String(id)
  }

  syncLockVersionField(version) {
    if (this.hasLockVersionTarget) {
      this.lockVersionTarget.value = String(version)
      return
    }
    let field = this.element.querySelector('input[name="entry[lock_version]"]')
    if (!field) {
      field = document.createElement("input")
      field.type = "hidden"
      field.name = "entry[lock_version]"
      this.element.appendChild(field)
    }
    field.value = String(version)
  }

  async sendSnapshot(snapshot) {
    const body = {
      entry_draft: {
        title: snapshot.title,
        raw_date: snapshot.rawDate,
        body_markdown: snapshot.bodyMarkdown,
        client_create_id: this.clientCreateIdValue || undefined
      }
    }
    if (this.entryIdValue > 0) {
      body.entry_draft.entry_id = this.entryIdValue
    }

    if (this.draftIdValue > 0) {
      body.entry_draft.lock_version = this.lockVersionValue
      return fetch(this.updateUrlTemplateValue.replace(":id", String(this.draftIdValue)), {
        method: "PATCH",
        headers: this.headers(),
        body: JSON.stringify(body),
        credentials: "same-origin"
      })
    }

    return fetch(this.createUrlValue, {
      method: "POST",
      headers: this.headers(),
      body: JSON.stringify(body),
      credentials: "same-origin"
    })
  }

  headers() {
    return {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-CSRF-Token": this.csrfToken()
    }
  }

  csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ""
  }

  scheduleRetry() {
    if (this.conflicted || this.gone) return
    if (this.retryTimer) clearTimeout(this.retryTimer)
    const delay = nextBackoffMs(this.retryAttempt)
    this.retryAttempt += 1
    this.retryTimer = setTimeout(() => {
      this.retryTimer = null
      this.saveNow({ force: true }).catch(() => {})
    }, delay)
  }

  flushBeacon() {
    if (this.conflicted || this.gone) return
    const snapshot = this.pendingSnapshot || this.readSnapshot()
    if (snapshotsEqual(snapshot, this.lastAckedSnapshot)) return

    const body = {
      entry_draft: {
        title: snapshot.title,
        raw_date: snapshot.rawDate,
        body_markdown: snapshot.bodyMarkdown,
        client_create_id: this.clientCreateIdValue || undefined
      }
    }
    if (this.entryIdValue > 0) body.entry_draft.entry_id = this.entryIdValue

    const token = this.csrfToken()
    if (this.draftIdValue > 0) {
      body.entry_draft.lock_version = this.lockVersionValue
      const url = this.updateUrlTemplateValue.replace(":id", String(this.draftIdValue))
      fetch(url, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": token
        },
        body: JSON.stringify(body),
        credentials: "same-origin",
        keepalive: true
      }).catch(() => {})
    } else if (this.createUrlValue) {
      fetch(this.createUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": token
        },
        body: JSON.stringify(body),
        credentials: "same-origin",
        keepalive: true
      }).catch(() => {})
    }
  }

  clearTimers() {
    if (this.debounceTimer) clearTimeout(this.debounceTimer)
    if (this.retryTimer) clearTimeout(this.retryTimer)
    this.debounceTimer = null
    this.retryTimer = null
  }

  setStatus(state) {
    if (!this.hasStatusTarget) return
    this.statusTarget.textContent = statusLabel(state)
    this.statusTarget.dataset.state = state || ""
  }
}
