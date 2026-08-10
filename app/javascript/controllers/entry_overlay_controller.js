import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "content", "body"]

  open(event) {
    const url = event.currentTarget.dataset.url
    if (!url) return

    fetch(url, { headers: { Accept: "text/html" } })
      .then(response => response.text())
      .then(html => {
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, "text/html")
        const detail = doc.querySelector(".entry-detail")
        this.bodyTarget.innerHTML = detail ? detail.innerHTML : html
        this.overlayTarget.classList.remove("hidden")
      })
  }

  close() {
    this.overlayTarget.classList.add("hidden")
  }

  closeOnBackdrop(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }
}
