const MONTHS = {
  jan: 1, feb: 2, mar: 3, apr: 4, may: 5, jun: 6,
  jul: 7, aug: 8, sep: 9, oct: 10, nov: 11, dec: 12
}

const MONTH_NAMES = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
const AMBIGUOUS_SLASH = /^\d{1,2}\/\d{1,2}\/\d{2,4}$/

export class DateParseError extends Error {
  constructor(message) {
    super(message)
    this.name = "DateParseError"
  }
}

function buildDate(year, month, day) {
  const date = new Date(Date.UTC(year, month - 1, day))
  if (
    date.getUTCFullYear() !== year ||
    date.getUTCMonth() !== month - 1 ||
    date.getUTCDate() !== day
  ) {
    throw new DateParseError("Invalid date")
  }
  return date
}

function fromISOWeek(year, week, day) {
  // Jan 4 is always in ISO week 1; day 1 = Monday … 7 = Sunday
  const jan4 = new Date(Date.UTC(year, 0, 4))
  const jan4Dow = jan4.getUTCDay() || 7
  const week1Monday = new Date(jan4)
  week1Monday.setUTCDate(jan4.getUTCDate() - jan4Dow + 1)
  const result = new Date(week1Monday)
  result.setUTCDate(week1Monday.getUTCDate() + (week - 1) * 7 + (day - 1))
  if (Number.isNaN(result.getTime()) || week < 1 || week > 53 || day < 1 || day > 7) {
    throw new DateParseError("Invalid ISO week date")
  }
  // Reject impossible weeks (e.g. W99)
  const checkWeek = isoWeekNumber(result)
  const checkYear = isoWeekYear(result)
  if (checkWeek !== week || checkYear !== year) {
    throw new DateParseError("Invalid ISO week date")
  }
  return result
}

export function isoWeekNumber(date) {
  const d = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()))
  const dayNum = d.getUTCDay() || 7
  d.setUTCDate(d.getUTCDate() + 4 - dayNum)
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1))
  return Math.ceil((((d - yearStart) / 86400000) + 1) / 7)
}

export function isoWeekYear(date) {
  const d = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()))
  const dayNum = d.getUTCDay() || 7
  d.setUTCDate(d.getUTCDate() + 4 - dayNum)
  return d.getUTCFullYear()
}

export function formatDisplayDate(date) {
  const day = String(date.getUTCDate()).padStart(2, "0")
  const month = MONTH_NAMES[date.getUTCMonth()]
  const year = date.getUTCFullYear()
  return `${day} ${month} ${year}`
}

export function parseDateInput(input) {
  const text = String(input ?? "").trim()
  if (!text) throw new DateParseError("Date cannot be blank")
  if (AMBIGUOUS_SLASH.test(text)) {
    throw new DateParseError(
      `"${text}" is ambiguous. Use a format such as: 09 Aug 2026, 09-Aug-2026, 2026-08-09, 20260809, 2026-W32-7`
    )
  }

  let match = text.match(/^(\d{2})[ -]([A-Za-z]{3})[ -](\d{4})$/)
  if (match) {
    const day = Number(match[1])
    const month = MONTHS[match[2].toLowerCase().slice(0, 3)]
    if (!month) throw new DateParseError("Invalid month name")
    return buildDate(Number(match[3]), month, day)
  }

  match = text.match(/^(\d{4})(\d{2})(\d{2})$/)
  if (match) {
    return buildDate(Number(match[1]), Number(match[2]), Number(match[3]))
  }

  match = text.match(/^(\d{4})-(\d{2})-(\d{2})$/)
  if (match) {
    return buildDate(Number(match[1]), Number(match[2]), Number(match[3]))
  }

  match = text.match(/^(\d{4})-W(\d{2})-(\d)$/i)
  if (match) {
    return fromISOWeek(Number(match[1]), Number(match[2]), Number(match[3]))
  }

  throw new DateParseError(`"${text}" is not a recognized date format`)
}

export function parseIsoDateOnly(iso) {
  const match = String(iso ?? "").trim().match(/^(\d{4})-(\d{2})-(\d{2})$/)
  if (!match) throw new DateParseError("Invalid ISO date")
  return buildDate(Number(match[1]), Number(match[2]), Number(match[3]))
}
