import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview", "editor"]

  togglePreview() {
    this.previewTarget.classList.toggle("hidden")
    this.editorTarget.classList.toggle("hidden")
    if (!this.previewTarget.classList.contains("hidden")) {
      const textarea = this.authoritativeTextarea()
      const value = textarea ? textarea.value : ""
      this.previewTarget.innerHTML = value.replace(/\n/g, "<br>")
    }
  }

  authoritativeTextarea() {
    if (!this.hasEditorTarget) return null
    return this.editorTarget.querySelector("textarea")
  }
}
