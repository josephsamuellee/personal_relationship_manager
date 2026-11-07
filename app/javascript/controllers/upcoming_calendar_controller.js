import { Controller } from "@hotwired/stimulus"

// Fetches Upcoming Calendar events asynchronously and populates day cells.
export default class extends Controller {
  static targets = ["status", "loading", "grid", "day", "events"]
  static values = {
    url: String,
    configUrl: String
  }

  connect() {
    this.requestId = 0
    this.abortController = null
    this.loadEvents()
  }

  disconnect() {
    this.abortInFlight()
  }

  async loadEvents() {
    const requestId = ++this.requestId
    this.abortInFlight()
    this.abortController = new AbortController()

    this.hideStatus()
    this.showLoading(true)

    try {
      const response = await fetch(this.urlValue, {
        headers: { Accept: "application/json" },
        credentials: "same-origin",
        signal: this.abortController.signal
      })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      const payload = await response.json()
      if (requestId !== this.requestId) return

      this.renderPayload(payload)
    } catch (error) {
      if (error.name === "AbortError") return
      if (requestId !== this.requestId) return
      this.showStatus("Google Calendar is temporarily unavailable.", "error")
      this.clearEvents()
    } finally {
      if (requestId === this.requestId) this.showLoading(false)
    }
  }

  renderPayload(payload) {
    const status = payload.status
    const message = payload.message

    if (status === "ok") {
      this.hideStatus()
      this.populateEvents(payload.events_by_date || {})
      return
    }

    this.clearEvents()

    if (status === "empty_allowlist" || status === "disconnected") {
      this.showStatus(this.configLinkMessage(message || "Configure Google Calendar."), "info")
      return
    }

    if (status === "reconnect_required") {
      this.showStatus(this.configLinkMessage(message || "Reconnect Google Calendar."), "reconnect")
      return
    }

    this.showStatus(message || "Google Calendar is temporarily unavailable.", "error")
  }

  populateEvents(eventsByDate) {
    this.dayTargets.forEach((day) => {
      const date = day.dataset.date
      const container = day.querySelector("[data-upcoming-calendar-target='events']")
      if (!container) return

      container.innerHTML = ""
      const events = eventsByDate[date] || []
      const visible = events.slice(0, 3)
      const overflow = events.slice(3)

      visible.forEach((event) => {
        container.appendChild(this.buildEventLink(date, event.title))
      })

      if (overflow.length > 0) {
        const more = document.createElement("button")
        more.type = "button"
        more.className = "upcoming-calendar-more"
        more.textContent = `+${overflow.length} more`
        more.addEventListener("click", () => {
          more.remove()
          overflow.forEach((event) => {
            container.appendChild(this.buildEventLink(date, event.title))
          })
        })
        container.appendChild(more)
      }
    })
  }

  buildEventLink(date, title) {
    const link = document.createElement("a")
    link.className = "upcoming-calendar-event"
    link.textContent = title
    link.title = title
    const params = new URLSearchParams({
      occurred_on: date,
      body: title
    })
    link.href = `/entries/new?${params.toString()}`
    link.dataset.turboFrame = "_top"
    return link
  }

  clearEvents() {
    this.dayTargets.forEach((day) => {
      const container = day.querySelector("[data-upcoming-calendar-target='events']")
      if (container) container.innerHTML = ""
    })
  }

  configLinkMessage(text) {
    const url = this.configUrlValue || "/config"
    return `${text} <a href="${url}">Open Config</a>`
  }

  showStatus(html, kind) {
    if (!this.hasStatusTarget) return
    this.statusTarget.hidden = false
    this.statusTarget.classList.remove("is-error", "is-reconnect", "is-info")
    this.statusTarget.classList.add(`is-${kind}`)
    this.statusTarget.innerHTML = html
  }

  hideStatus() {
    if (!this.hasStatusTarget) return
    this.statusTarget.hidden = true
    this.statusTarget.textContent = ""
  }

  showLoading(visible) {
    if (!this.hasLoadingTarget) return
    this.loadingTarget.hidden = !visible
  }

  abortInFlight() {
    if (this.abortController) {
      this.abortController.abort()
      this.abortController = null
    }
  }
}
