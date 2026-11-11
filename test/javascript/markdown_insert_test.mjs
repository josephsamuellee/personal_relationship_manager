import assert from "node:assert/strict"
import test from "node:test"
import { insertAtRange, resolveInsertRange, wikiPersonReference } from "../../app/javascript/markdown_insert.js"

test("wikiPersonReference wraps the exact name", () => {
  assert.equal(wikiPersonReference("Ada Lovelace"), "[[Ada Lovelace]]")
})

test("inserts at caret without adding whitespace", () => {
  const result = insertAtRange("Hello world", "[[Ada Lovelace]]", { start: 6, end: 6 })
  assert.equal(result.value, "Hello [[Ada Lovelace]]world")
  assert.equal(result.caret, 6 + "[[Ada Lovelace]]".length)
})

test("replaces only the selected text", () => {
  const result = insertAtRange("Hello world", "[[Ada Lovelace]]", { start: 6, end: 11 })
  assert.equal(result.value, "Hello [[Ada Lovelace]]")
  assert.equal(result.caret, "Hello [[Ada Lovelace]]".length)
})

test("appends when selection is missing", () => {
  const result = insertAtRange("Body", "[[Ada Lovelace]]", null)
  assert.equal(result.value, "Body[[Ada Lovelace]]")
  assert.equal(result.caret, "Body[[Ada Lovelace]]".length)
})

test("appends when selection is out of range", () => {
  const range = resolveInsertRange("Body", { start: 99, end: 100 })
  assert.deepEqual(range, { start: 4, end: 4 })
})

test("repeated inserts stack exactly", () => {
  let value = "Start"
  ;["Ada Lovelace", "Grace Hopper"].forEach((name) => {
    const inserted = insertAtRange(value, wikiPersonReference(name), {
      start: value.length,
      end: value.length
    })
    value = inserted.value
  })
  assert.equal(value, "Start[[Ada Lovelace]][[Grace Hopper]]")
})
