import { Controller } from "@hotwired/stimulus"

const COLLISION_THRESHOLD = 20

export default class extends Controller {
  static targets = ["container", "axis", "nodes", "data"]

  connect() {
    this.entries = JSON.parse(this.dataTarget.textContent)
    this.render()
  }

  render() {
    if (this.entries.length === 0) return

    const today = new Date()
    today.setHours(0, 0, 0, 0)

    const dates = this.entries.map(e => new Date(e.occurred_on))
    const minDate = dates.reduce((a, b) => (a < b ? a : b))
    const maxDate = today
    const range = maxDate - minDate || 1
    const width = this.containerTarget.offsetWidth || 800

    const positioned = this.entries.map(entry => {
      const date = new Date(entry.occurred_on)
      const ratio = (date - minDate) / range
      const x = ratio * (width - 40) + 20
      return { ...entry, x }
    })

    positioned.sort((a, b) => a.x - b.x)

    const lanes = []
    positioned.forEach(entry => {
      let lane = 0
      while (lanes[lane] && entry.x - lanes[lane] < COLLISION_THRESHOLD) {
        lane++
      }
      lanes[lane] = entry.x
      entry.lane = lane
    })

    this.nodesTarget.innerHTML = ""
    positioned.forEach(entry => {
      const node = document.createElement("div")
      node.className = "timeline-node"
      node.style.left = `${entry.x}px`
      node.style.bottom = `${entry.lane * 28}px`
      node.dataset.entryId = entry.id
      node.dataset.url = entry.url
      node.dataset.action = "click->entry-overlay#open"

      const dot = document.createElement("div")
      dot.className = `timeline-node-dot${entry.primary ? "" : " secondary"}`
      dot.title = entry.title

      const label = document.createElement("div")
      label.className = "timeline-node-label"
      label.textContent = entry.title

      node.appendChild(dot)
      node.appendChild(label)
      this.nodesTarget.appendChild(node)
    })
  }
}
