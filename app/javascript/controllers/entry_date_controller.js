import { Controller } from "@hotwired/stimulus"
import {
  DateParseError,
  formatDisplayDate,
  isoWeekNumber,
  parseDateInput,
  parseIsoDateOnly
} from "date_parse"

const WEEKDAYS = ["M", "T", "W", "T", "F", "S", "S"]
const MONTH_LABELS = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
]

export default class extends Controller {
  static targets = ["input", "picker", "error", "pickButton"]
  static values = {
    today: String,
    todayDisplay: String
  }

  connect() {
    this.viewYear = null
    this.viewMonth = null // 0-based
    this.selectedDate = null
    this.boundKeydown = this.onKeydown.bind(this)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown)
  }

  useToday() {
    this.clearError()
    if (this.hasTodayDisplayValue && this.todayDisplayValue) {
      this.inputTarget.value = this.todayDisplayValue
      return
    }
    if (this.hasTodayValue && this.todayValue) {
      try {
        this.inputTarget.value = formatDisplayDate(parseIsoDateOnly(this.todayValue))
        return
      } catch (_error) {
        // fall through
      }
    }
    const now = new Date()
    const utc = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate()))
    this.inputTarget.value = formatDisplayDate(utc)
  }

  togglePicker(event) {
    event.preventDefault()
    if (!this.pickerTarget.hidden) {
      this.closePicker()
      return
    }
    this.openPicker()
  }

  openPicker() {
    this.clearError()
    const raw = this.inputTarget.value
    let date
    try {
      date = parseDateInput(raw)
    } catch (error) {
      const message = error instanceof DateParseError
        ? "Correct the date before opening the calendar. Use an unambiguous format such as 09 Aug 2026."
        : "Correct the date before opening the calendar."
      this.showError(message)
      this.inputTarget.setAttribute("aria-invalid", "true")
      return
    }

    this.inputTarget.removeAttribute("aria-invalid")
    this.selectedDate = date
    this.viewYear = date.getUTCFullYear()
    this.viewMonth = date.getUTCMonth()
    this.renderPicker()
    this.pickerTarget.hidden = false
    if (this.hasPickButtonTarget) {
      this.pickButtonTarget.setAttribute("aria-expanded", "true")
    }
    document.addEventListener("keydown", this.boundKeydown)
  }

  closePicker() {
    this.pickerTarget.hidden = true
    this.pickerTarget.innerHTML = ""
    if (this.hasPickButtonTarget) {
      this.pickButtonTarget.setAttribute("aria-expanded", "false")
    }
    document.removeEventListener("keydown", this.boundKeydown)
  }

  onKeydown(event) {
    if (event.key === "Escape" && !this.pickerTarget.hidden) {
      event.preventDefault()
      this.closePicker()
    }
  }

  previousMonth(event) {
    event.preventDefault()
    this.shiftMonth(-1)
  }

  nextMonth(event) {
    event.preventDefault()
    this.shiftMonth(1)
  }

  changeYear(event) {
    const year = Number(event.target.value)
    if (!Number.isFinite(year)) return
    this.viewYear = year
    this.renderPicker()
  }

  selectDay(event) {
    event.preventDefault()
    const button = event.currentTarget
    const year = Number(button.dataset.year)
    const month = Number(button.dataset.month)
    const day = Number(button.dataset.day)
    const date = new Date(Date.UTC(year, month, day))
    this.inputTarget.value = formatDisplayDate(date)
    this.clearError()
    this.inputTarget.removeAttribute("aria-invalid")
    this.closePicker()
  }

  shiftMonth(delta) {
    const cursor = new Date(Date.UTC(this.viewYear, this.viewMonth + delta, 1))
    this.viewYear = cursor.getUTCFullYear()
    this.viewMonth = cursor.getUTCMonth()
    this.renderPicker()
  }

  renderPicker() {
    const year = this.viewYear
    const month = this.viewMonth
    const first = new Date(Date.UTC(year, month, 1))
    const startOffset = (first.getUTCDay() + 6) % 7 // Monday = 0
    const gridStart = new Date(Date.UTC(year, month, 1 - startOffset))

    const header = document.createElement("div")
    header.className = "date-picker-header"

    const prev = document.createElement("button")
    prev.type = "button"
    prev.className = "date-picker-nav"
    prev.setAttribute("aria-label", "Previous month")
    prev.textContent = "‹"
    prev.dataset.action = "entry-date#previousMonth"

    const label = document.createElement("div")
    label.className = "date-picker-month-label"
    label.textContent = `${MONTH_LABELS[month]} ${year}`

    const yearSelect = document.createElement("select")
    yearSelect.className = "date-picker-year"
    yearSelect.setAttribute("aria-label", "Select year")
    yearSelect.dataset.action = "entry-date#changeYear"
    const todayYear = this.todayYear()
    const minYear = Math.min(1970, year, todayYear)
    const maxYear = Math.max(todayYear + 10, year)
    for (let y = minYear; y <= maxYear; y += 1) {
      const option = document.createElement("option")
      option.value = String(y)
      option.textContent = String(y)
      if (y === year) option.selected = true
      yearSelect.appendChild(option)
    }

    const next = document.createElement("button")
    next.type = "button"
    next.className = "date-picker-nav"
    next.setAttribute("aria-label", "Next month")
    next.textContent = "›"
    next.dataset.action = "entry-date#nextMonth"

    header.append(prev, label, yearSelect, next)

    const table = document.createElement("table")
    table.className = "date-picker-table"

    const thead = document.createElement("thead")
    const headRow = document.createElement("tr")
    const weekHead = document.createElement("th")
    weekHead.className = "date-picker-week"
    weekHead.textContent = "W"
    weekHead.scope = "col"
    headRow.appendChild(weekHead)
    WEEKDAYS.forEach((day) => {
      const th = document.createElement("th")
      th.scope = "col"
      th.textContent = day
      headRow.appendChild(th)
    })
    thead.appendChild(headRow)
    table.appendChild(thead)

    const tbody = document.createElement("tbody")
    const cursor = new Date(gridStart)
    for (let week = 0; week < 6; week += 1) {
      const row = document.createElement("tr")
      const weekCell = document.createElement("td")
      weekCell.className = "date-picker-week"
      weekCell.textContent = `W${String(isoWeekNumber(cursor)).padStart(2, "0")}`
      row.appendChild(weekCell)

      for (let dow = 0; dow < 7; dow += 1) {
        const cell = document.createElement("td")
        const button = document.createElement("button")
        button.type = "button"
        button.className = "date-picker-day"
        button.textContent = String(cursor.getUTCDate())
        button.dataset.year = String(cursor.getUTCFullYear())
        button.dataset.month = String(cursor.getUTCMonth())
        button.dataset.day = String(cursor.getUTCDate())
        button.dataset.action = "entry-date#selectDay"
        button.setAttribute(
          "aria-label",
          formatDisplayDate(cursor)
        )

        if (cursor.getUTCMonth() !== month) {
          button.classList.add("is-adjacent")
        }
        if (
          this.selectedDate &&
          cursor.getUTCFullYear() === this.selectedDate.getUTCFullYear() &&
          cursor.getUTCMonth() === this.selectedDate.getUTCMonth() &&
          cursor.getUTCDate() === this.selectedDate.getUTCDate()
        ) {
          button.classList.add("is-selected")
          button.setAttribute("aria-current", "date")
        }

        cell.appendChild(button)
        row.appendChild(cell)
        cursor.setUTCDate(cursor.getUTCDate() + 1)
      }
      tbody.appendChild(row)
    }
    table.appendChild(tbody)

    this.pickerTarget.replaceChildren(header, table)
  }

  todayYear() {
    if (this.hasTodayValue && this.todayValue) {
      try {
        return parseIsoDateOnly(this.todayValue).getUTCFullYear()
      } catch (_error) {
        // fall through
      }
    }
    return new Date().getFullYear()
  }

  showError(message) {
    if (!this.hasErrorTarget) return
    this.errorTarget.hidden = false
    this.errorTarget.textContent = message
  }

  clearError() {
    if (!this.hasErrorTarget) return
    this.errorTarget.hidden = true
    this.errorTarget.textContent = ""
  }
}
