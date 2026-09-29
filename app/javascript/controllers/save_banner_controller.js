import { Controller } from "@hotwired/stimulus"

// Shows the successful-save banner briefly, with Home dropped below it,
// then hides the banner and returns Home to its shared resting position.
export default class extends Controller {
  static values = {
    hideAfter: { type: Number, default: 3000 }
  }

  connect() {
    this.nav = document.querySelector(".floating-nav-top")
    this.placeHomeBelowBanner()
    this.timer = window.setTimeout(() => this.dismiss(), this.hideAfterValue)
  }

  disconnect() {
    window.clearTimeout(this.timer)
  }

  placeHomeBelowBanner() {
    if (!this.nav) return

    const gap = 12
    const top = Math.ceil(this.element.getBoundingClientRect().height) + gap
    this.nav.style.top = `${top}px`
  }

  dismiss() {
    this.element.classList.add("hidden")
    document.body.classList.remove("has-save-banner")
    if (this.nav) this.nav.style.top = ""
  }
}
