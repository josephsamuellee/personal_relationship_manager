import assert from "node:assert/strict"
import test from "node:test"
import {
  DateParseError,
  formatDisplayDate,
  isoWeekNumber,
  parseDateInput
} from "../../app/javascript/date_parse.js"

function utcDate(year, month, day) {
  return new Date(Date.UTC(year, month - 1, day))
}

test("parses DD MMM YYYY", () => {
  assert.deepEqual(parseDateInput("09 Aug 2026"), utcDate(2026, 8, 9))
})

test("parses DD-MMM-YYYY", () => {
  assert.deepEqual(parseDateInput("09-Aug-2026"), utcDate(2026, 8, 9))
})

test("parses YYYYMMDD", () => {
  assert.deepEqual(parseDateInput("20260809"), utcDate(2026, 8, 9))
})

test("parses ISO date", () => {
  assert.deepEqual(parseDateInput("2026-08-09"), utcDate(2026, 8, 9))
})

test("parses ISO week date", () => {
  assert.deepEqual(parseDateInput("2026-W32-7"), utcDate(2026, 8, 9))
})

test("rejects ambiguous slash dates", () => {
  assert.throws(() => parseDateInput("08/09/26"), DateParseError)
  assert.throws(() => parseDateInput("08/09/2026"), DateParseError)
  assert.throws(() => parseDateInput("9/8/26"), DateParseError)
})

test("rejects garbage", () => {
  assert.throws(() => parseDateInput("garbage"), DateParseError)
})

test("rejects invalid ISO week", () => {
  assert.throws(() => parseDateInput("2026-W99-7"), DateParseError)
})

test("formats display date like strftime %d %b %Y", () => {
  assert.equal(formatDisplayDate(utcDate(2026, 10, 20)), "20 Oct 2026")
})

test("ISO week number at year boundary", () => {
  // 2026-12-28 is Monday of ISO week 53 of 2026
  assert.equal(isoWeekNumber(utcDate(2026, 12, 28)), 53)
  // 2027-01-01 is Friday of ISO week 53 of 2026
  assert.equal(isoWeekNumber(utcDate(2027, 1, 1)), 53)
})
