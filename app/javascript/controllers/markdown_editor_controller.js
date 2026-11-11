import { Controller } from "@hotwired/stimulus"
import { insertAtRange } from "markdown_insert"

// Progressive enhancement: keep a native textarea as fallback; replace with
// OverType when the ESM module loads. Only one named Markdown field submits.
export default class extends Controller {
  static targets = ["mount", "fallback"]
  static values = {
    theme: { type: String, default: "dark" }
  }

  connect() {
    this.editor = null
    this.enhanceToken = 0
    this.lastSelection = null
    this.boundBeforeCache = this.handleBeforeCache.bind(this)
    this.boundTrackSelection = this.trackSelection.bind(this)
    document.addEventListener("turbo:before-cache", this.boundBeforeCache)
    document.addEventListener("selectionchange", this.boundTrackSelection)
    this.enhance()
  }

  disconnect() {
    this.enhanceToken += 1
    document.removeEventListener("turbo:before-cache", this.boundBeforeCache)
    document.removeEventListener("selectionchange", this.boundTrackSelection)
    this.unbindTextareaTracking()
    this.teardownToNative({ preserveValue: true })
  }

  handleBeforeCache() {
    // Snapshot a clean native textarea so Turbo cache does not restore OverType chrome.
    this.teardownToNative({ preserveValue: true })
  }

  async enhance() {
    if (!this.hasMountTarget || !this.hasFallbackTarget) return
    if (this.editor) return

    const token = ++this.enhanceToken
    const fallback = this.fallbackTarget
    const initialValue = fallback.value
    const fieldName = fallback.getAttribute("name")
    const fieldId = fallback.id
    const required = fallback.required
    const rows = fallback.rows || 12

    let OverTypeModule
    try {
      OverTypeModule = await import("overtype")
    } catch (error) {
      console.warn("OverType failed to load; keeping native textarea.", error)
      this.bindTextareaTracking(fallback)
      return
    }

    if (token !== this.enhanceToken) return

    const OverType = OverTypeModule.default || OverTypeModule.OverType
    const toolbarButtons = OverTypeModule.toolbarButtons
    if (!OverType) {
      console.warn("OverType export missing; keeping native textarea.")
      this.bindTextareaTracking(fallback)
      return
    }

    const mount = this.mountTarget
    // Remove the fallback from the tree so only OverType's textarea submits.
    fallback.remove()
    mount.replaceChildren()

    const theme = this.themeValue === "light" ? "solar" : "cave"
    const limitedToolbar = toolbarButtons
      ? [
          toolbarButtons.bold,
          toolbarButtons.italic,
          toolbarButtons.separator,
          toolbarButtons.link,
          toolbarButtons.separator,
          toolbarButtons.h1,
          toolbarButtons.h2,
          toolbarButtons.h3,
          toolbarButtons.separator,
          toolbarButtons.bulletList,
          toolbarButtons.orderedList
        ]
      : null

    try {
      const instances = new OverType(mount, {
        value: initialValue,
        theme,
        toolbar: true,
        toolbarButtons: limitedToolbar || undefined,
        autofocus: false,
        textareaProps: {
          name: fieldName,
          id: fieldId || undefined,
          required: required || undefined,
          rows
        }
      })
      if (token !== this.enhanceToken) {
        const editor = Array.isArray(instances) ? instances[0] : instances
        editor?.destroy?.()
        return
      }

      this.editor = Array.isArray(instances) ? instances[0] : instances
      this.initialBrowserMarkdown = initialValue

      // Guard exact no-op: if OverType rewrote value on init, restore exact string.
      if (this.editor && this.editor.getValue() !== initialValue) {
        this.editor.setValue(initialValue)
      }

      this.bindTextareaTracking(this.activeTextarea())
    } catch (error) {
      console.warn("OverType failed to initialize; restoring native textarea.", error)
      this.restoreFallback({
        name: fieldName,
        id: fieldId,
        required,
        rows,
        value: initialValue
      })
      this.bindTextareaTracking(this.activeTextarea())
    }
  }

  // Insert exact text at last known caret/selection; append when none is usable.
  insertMarkdown(text) {
    const textarea = this.activeTextarea()
    if (!textarea) return

    const current = typeof this.editor?.getValue === "function" ? this.editor.getValue() : textarea.value
    const result = insertAtRange(current, text, this.lastSelection)

    if (this.editor && typeof this.editor.setValue === "function") {
      this.editor.setValue(result.value)
    } else {
      textarea.value = result.value
      textarea.dispatchEvent(new Event("input", { bubbles: true }))
    }

    textarea.focus()
    textarea.setSelectionRange(result.caret, result.caret)
    this.lastSelection = { start: result.caret, end: result.caret }

    if (this.editor && typeof this.editor._refreshFromTextarea === "function") {
      this.editor._refreshFromTextarea()
    }
  }

  trackSelection() {
    const textarea = this.activeTextarea()
    if (!textarea) return
    if (document.activeElement !== textarea) return

    this.lastSelection = {
      start: textarea.selectionStart,
      end: textarea.selectionEnd
    }
  }

  captureSelectionFromTextarea() {
    const textarea = this.activeTextarea()
    if (!textarea) return

    this.lastSelection = {
      start: textarea.selectionStart,
      end: textarea.selectionEnd
    }
  }

  teardownToNative({ preserveValue }) {
    const value = this.currentMarkdown()
    const meta = this.fieldMetaFromDom()

    this.unbindTextareaTracking()

    if (this.editor) {
      try {
        this.editor.destroy()
      } catch (_) {
        // ignore destroy errors during Turbo teardown
      }
      this.editor = null
    }

    if (!this.hasMountTarget) return

    this.restoreFallback({
      name: meta.name,
      id: meta.id,
      required: meta.required,
      rows: meta.rows,
      value: preserveValue ? value : meta.value
    })
    this.bindTextareaTracking(this.activeTextarea())
  }

  currentMarkdown() {
    if (this.editor && typeof this.editor.getValue === "function") {
      return this.editor.getValue()
    }
    const textarea = this.mountTarget?.querySelector("textarea")
    return textarea ? textarea.value : ""
  }

  activeTextarea() {
    if (this.editor?.textarea) return this.editor.textarea
    if (this.hasFallbackTarget) return this.fallbackTarget
    return this.mountTarget?.querySelector("textarea") || null
  }

  bindTextareaTracking(textarea) {
    this.unbindTextareaTracking()
    if (!textarea) return

    this.trackedTextarea = textarea
    this.boundBlurCapture = this.captureSelectionFromTextarea.bind(this)
    this.boundKeyupCapture = this.captureSelectionFromTextarea.bind(this)
    this.boundClickCapture = this.captureSelectionFromTextarea.bind(this)
    textarea.addEventListener("blur", this.boundBlurCapture)
    textarea.addEventListener("keyup", this.boundKeyupCapture)
    textarea.addEventListener("click", this.boundClickCapture)
  }

  unbindTextareaTracking() {
    if (!this.trackedTextarea) return

    this.trackedTextarea.removeEventListener("blur", this.boundBlurCapture)
    this.trackedTextarea.removeEventListener("keyup", this.boundKeyupCapture)
    this.trackedTextarea.removeEventListener("click", this.boundClickCapture)
    this.trackedTextarea = null
  }

  fieldMetaFromDom() {
    const textarea = this.mountTarget?.querySelector("textarea") || this.fallbackTarget
    return {
      name: textarea?.getAttribute("name") || "entry[body_markdown]",
      id: textarea?.id || "",
      required: Boolean(textarea?.required),
      rows: textarea?.rows || 12,
      value: textarea?.value || ""
    }
  }

  restoreFallback({ name, id, required, rows, value }) {
    if (!this.hasMountTarget) return

    const textarea = document.createElement("textarea")
    textarea.name = name
    if (id) textarea.id = id
    textarea.rows = rows || 12
    textarea.required = Boolean(required)
    textarea.value = value ?? ""
    textarea.dataset.markdownEditorTarget = "fallback"
    textarea.className = this.element.dataset.fallbackClass || ""

    this.mountTarget.replaceChildren(textarea)
  }
}
