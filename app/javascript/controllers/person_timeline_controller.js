import { Controller } from "@hotwired/stimulus"

const COLLISION_THRESHOLD = 20
const HORIZONTAL_PADDING = 20

export default class extends Controller {
  static targets = ["container", "axis", "nodes", "data"]

  connect() {
    this.entries = JSON.parse(this.dataTarget.textContent)
    this.render()
  }

  render() {
    if (this.entries.length === 0) return

    const dates = this.entries.map(e => parseISODate(e.occurred_on))
    const minDate = dates.reduce((a, b) => (a < b ? a : b))
    const maxDate = dates.reduce((a, b) => (a > b ? a : b))
    const range = maxDate - minDate
    const width = this.containerTarget.offsetWidth || 800
    const innerWidth = width - HORIZONTAL_PADDING * 2

    const positionFor = (date) => {
      if (range === 0) return HORIZONTAL_PADDING
      return ((date - minDate) / range) * innerWidth + HORIZONTAL_PADDING
    }

    const positioned = this.entries.map(entry => {
      const date = parseISODate(entry.occurred_on)
      return { ...entry, date, x: positionFor(date) }
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
    this.containerTarget.querySelectorAll(".timeline-year-label, .timeline-year-tick").forEach(el => el.remove())

    const yearLabel = document.createElement("div")
    yearLabel.className = "timeline-year-label"
    yearLabel.textContent = String(minDate.getFullYear())
    yearLabel.style.left = `${positionFor(minDate)}px`
    this.containerTarget.appendChild(yearLabel)

    yearBoundaryDates(minDate, maxDate).forEach(date => {
      const year = String(date.getFullYear())
      const tick = document.createElement("div")
      tick.className = "timeline-year-tick"
      tick.style.left = `${positionFor(date)}px`
      tick.dataset.year = year
      tick.title = year
      tick.setAttribute("aria-label", year)
      this.containerTarget.appendChild(tick)
    })

    positioned.forEach(entry => {
      const hoverText = `${formatYearMonth(entry.date)} ${entry.title}`
      const node = document.createElement("div")
      node.className = "timeline-node"
      node.style.left = `${entry.x}px`
      node.style.bottom = `${entry.lane * 28}px`
      node.dataset.entryId = entry.id
      node.dataset.url = entry.url
      node.dataset.hover = hoverText
      node.title = hoverText
      node.dataset.action = "click->entry-overlay#open"

      const dot = document.createElement("div")
      dot.className = `timeline-node-dot${entry.primary ? "" : " secondary"}`

      const label = document.createElement("div")
      label.className = "timeline-node-label"
      label.textContent = entry.title

      node.appendChild(dot)
      node.appendChild(label)
      this.nodesTarget.appendChild(node)
    })
  }
}

function parseISODate(iso) {
  const [year, month, day] = String(iso).slice(0, 10).split("-").map(Number)
  return new Date(year, month - 1, day)
}

function formatYearMonth(date) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, "0")
  return `${year}${month}`
}

function yearBoundaryDates(minDate, maxDate) {
  const ticks = []
  for (let year = minDate.getFullYear() + 1; year <= maxDate.getFullYear(); year++) {
    const date = new Date(year, 0, 1)
    if (date > minDate && date < maxDate) ticks.push(date)
  }
  return ticks
}
