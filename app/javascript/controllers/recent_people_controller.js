import { Controller } from "@hotwired/stimulus"
import { wikiPersonReference } from "markdown_insert"

// Entry-form companion: Recent People buttons insert [[Name]] into the body editor.
export default class extends Controller {
  static outlets = ["markdown-editor"]

  // Prevent the button from taking focus so the editor caret/selection stays put.
  preserveSelection(event) {
    event.preventDefault()
  }

  insert(event) {
    const name = event.params.name
    if (!name) return

    if (!this.hasMarkdownEditorOutlet) {
      console.warn("Recent People: markdown editor outlet not found.")
      return
    }

    this.markdownEditorOutlet.insertMarkdown(wikiPersonReference(name))
  }
}
