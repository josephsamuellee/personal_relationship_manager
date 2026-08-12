import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.#logNavLayout("initial")
    document.addEventListener("turbo:load", this.#onTurboLoad)
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.#onTurboLoad)
  }

  #onTurboLoad = () => {
    this.#logNavLayout("turbo-load")
  }

  #logNavLayout(trigger) {
    const selectors = [
      { key: "floatingHome", selector: ".floating-home" },
      { key: "floatingSearch", selector: ".floating-search" },
      { key: "floatingDraft", selector: ".floating-draft" },
      { key: "floatingAdd", selector: ".floating-add" }
    ]

    const elements = {}
    selectors.forEach(({ key, selector }) => {
      const nodes = document.querySelectorAll(selector)
      elements[key] = Array.from(nodes).map((el) => this.#elementSnapshot(el))
    })

  // #region agent log
    fetch("http://127.0.0.1:7545/ingest/4f82b231-db51-4f06-a3eb-c7c7beee55c9", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Debug-Session-Id": "3d099f" },
      body: JSON.stringify({
        sessionId: "3d099f",
        runId: "post-fix",
        hypothesisId: "A-B-C-D",
        location: "nav_debug_controller.js:logNavLayout",
        message: "Nav element layout snapshot",
        data: {
          trigger,
          path: window.location.pathname,
          draftInSession: this.element.dataset.draftInSession === "true",
          elements
        },
        timestamp: Date.now()
      })
    }).catch(() => {})
  // #endregion
  }

  #elementSnapshot(el) {
    const style = window.getComputedStyle(el)
    const rect = el.getBoundingClientRect()
    const offsetParent = el.offsetParent
    let ancestorTransform = null
    let node = el.parentElement
    while (node && node !== document.body) {
      const s = window.getComputedStyle(node)
      if (s.transform !== "none" || s.filter !== "none" || s.perspective !== "none") {
        ancestorTransform = { tag: node.tagName, className: node.className, transform: s.transform, filter: s.filter }
        break
      }
      node = node.parentElement
    }

    return {
      tag: el.tagName,
      className: el.className,
      position: style.position,
      top: style.top,
      right: style.right,
      bottom: style.bottom,
      left: style.left,
      zIndex: style.zIndex,
      rect: { top: rect.top, left: rect.left, width: rect.width, height: rect.height },
      offsetParentTag: offsetParent ? offsetParent.tagName : null,
      ancestorTransform
    }
  }
}
