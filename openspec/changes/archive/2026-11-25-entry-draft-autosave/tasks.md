# Tasks

## 1. Draft HTTP API for autosave

- [x] 1.1 Add create/update draft endpoints that upsert title/raw_date/body_markdown/(entry_id) without calling EntrySaver or creating People; verify request tests for create-on-POST, update-on-PATCH, and no Entry/Person side effects with unresolved wiki links
- [x] 1.2 Ensure responses include draft id and content_updated_at (and lock_version if present); verify JSON/HTML response contract used by the Stimulus client

## 2. Stimulus autosave and statuses

- [x] 2.1 Implement `entry-draft-autosave` on Entry New/Edit forms with 3s idle debounce, dirty snapshot compare, create-then-patch flow, and status UI (unsaved/saving/saved/retrying); verify JS unit or system coverage that unchanged content skips writes and first edit after open creates a draft only after debounce
- [x] 2.2 Wire OverType/Recent People/title/date inputs into dirty tracking; verify Person About pages do not mount Entry autosave
- [x] 2.3 Implement bounded backoff retry that only sends the latest payload; verify a failed autosave keeps editor content and a later success acknowledges saved status

## 3. URL replace and Save flush

- [x] 3.1 Add draft editor route/view; on first New create ACK, `history.replaceState` to that URL; verify refresh resumes the same draft and `/entries/new` still starts blank
- [x] 3.2 On explicit Save, flush pending autosave / include latest DOM fields; verify Save before debounce persists the latest body (valid path or resolution path)
- [x] 3.3 Add `beforeunload` and Turbo before-visit protection when dirty/unacked; verify navigation attempts while dirty prompt or flush rather than silently dropping edits

## 4. Integration verification

- [x] 4.1 Run autosave-related controller/JS/system tests and confirm scenarios under this change’s `specs/persistent-entry-drafts`, `specs/entries`, and `specs/markdown-editor` deltas

## Workflow follow-up

- Apply after `persistent-entry-drafts-storage`. Next: `entry-draft-multi-and-management`, then `entry-draft-concurrency`.
