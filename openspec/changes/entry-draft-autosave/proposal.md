# Proposal

## Why

Durable draft rows from `persistent-entry-drafts-storage` still require explicit Save or resolution staging to write the server. Users typing long journal entries need automatic persistence shortly after they pause so content survives navigation and brief disconnects without committing Entries.

## What Changes

- Add Entry-editor autosave that debounces **3 seconds** after the last meaningful modification of title, date, or Markdown.
- Create a persistent draft only after the first meaningful modification; opening New/Edit without edits creates no row.
- After the first successful New-draft create, replace the browser URL to the draft editor route so refresh resumes that draft; `/entries/new` remains a fresh workflow.
- Show editor statuses: Unsaved changes, Saving draft, Draft saved, Not saved — retrying (bounded backoff). Conflict UI is deferred to `entry-draft-concurrency`.
- Do not autosave unchanged content; coalesce in-flight requests to the latest payload; never call Entry persistence, Person creation, or relationship/tag writes from autosave.
- Protect against accidental loss of unacknowledged edits on Turbo navigation and browser unload (prompt and/or best-effort flush). No browser-local persistent journal storage.
- No maximum-wait checkpoint during continuous typing in this change (idle debounce only).
- Out of scope: multi-draft Config UI, floating MRU redesign, optimistic-lock conflict banners, Person About autosave, Redis/background jobs, real-time sync.

## Capabilities

### New Capabilities
- _(none)_ — autosave behavior extends `persistent-entry-drafts`.

### Modified Capabilities
- `persistent-entry-drafts`: Add autosave lifecycle, visible statuses, retry behavior, and New-entry URL replace after first create.
- `entries`: New Entry stays blank until user edits; Edit may bind to a draft id after first modification; explicit Save still required to commit.
- `markdown-editor`: Autosave must observe OverType/input events without breaking exact Markdown submission or Turbo lifecycle.

## Impact

- Depends on `persistent-entry-drafts-storage` (draft table + draft id routes).
- New Stimulus controller on Entry forms; optional JSON draft create/update endpoints.
- New/Edit views: status region, hidden draft id, draft editor route for resume-after-create.
- Tests for debounce semantics (via controller/request + JS unit where practical), no-create-on-open, URL replace, retry, navigation guard.
- Follow-on: `entry-draft-multi-and-management`, `entry-draft-concurrency`.
