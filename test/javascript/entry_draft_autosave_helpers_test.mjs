import assert from "node:assert/strict"
import test from "node:test"
import {
  buildSnapshot,
  conflictReloadState,
  nextBackoffMs,
  shouldHaltAutosaveAfterStatus,
  snapshotsEqual,
  statusLabel
} from "../../app/javascript/entry_draft_autosave_helpers.js"

test("snapshotsEqual is true for identical field sets", () => {
  const a = buildSnapshot({ title: "T", rawDate: "1 Jan", bodyMarkdown: "Body" })
  const b = buildSnapshot({ title: "T", rawDate: "1 Jan", bodyMarkdown: "Body" })
  assert.equal(snapshotsEqual(a, b), true)
})

test("snapshotsEqual is false when body changes", () => {
  const a = buildSnapshot({ title: "T", rawDate: "1 Jan", bodyMarkdown: "Body" })
  const b = buildSnapshot({ title: "T", rawDate: "1 Jan", bodyMarkdown: "Body!" })
  assert.equal(snapshotsEqual(a, b), false)
})

test("nextBackoffMs caps at 30 seconds", () => {
  assert.equal(nextBackoffMs(0), 2000)
  assert.equal(nextBackoffMs(1), 5000)
  assert.equal(nextBackoffMs(2), 15000)
  assert.equal(nextBackoffMs(3), 30000)
  assert.equal(nextBackoffMs(99), 30000)
})

test("statusLabel covers autosave states", () => {
  assert.equal(statusLabel("unsaved"), "Unsaved changes")
  assert.equal(statusLabel("saving"), "Saving draft…")
  assert.equal(statusLabel("saved"), "Draft saved")
  assert.equal(statusLabel("retrying"), "Not saved — retrying")
  assert.equal(statusLabel("conflict"), "Conflict detected")
})

test("conflictReloadState replaces editor with server and keeps local copy", () => {
  const local = buildSnapshot({ title: "Local", rawDate: "1 Jan", bodyMarkdown: "local md" })
  const state = conflictReloadState(
    { title: "Server", raw_date: "2 Jan", body_markdown: "server md", lock_version: 3 },
    local
  )
  assert.equal(state.title, "Server")
  assert.equal(state.rawDate, "2 Jan")
  assert.equal(state.bodyMarkdown, "server md")
  assert.equal(state.localCopy, "local md")
  assert.equal(state.lockVersion, 3)
})

test("shouldHaltAutosaveAfterStatus for conflict and gone", () => {
  assert.equal(shouldHaltAutosaveAfterStatus(409), true)
  assert.equal(shouldHaltAutosaveAfterStatus(404), true)
  assert.equal(shouldHaltAutosaveAfterStatus(410), true)
  assert.equal(shouldHaltAutosaveAfterStatus(500), false)
})
