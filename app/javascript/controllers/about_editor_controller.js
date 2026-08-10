import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "preview", "editor"]

  togglePreview() {
    this.previewTarget.classList.toggle("hidden")
    this.editorTarget.classList.toggle("hidden")
    if (!this.previewTarget.classList.contains("hidden")) {
      this.previewTarget.innerHTML = this.textareaTarget.value.replace(/\n/g, "<br>")
    }
  }
}
