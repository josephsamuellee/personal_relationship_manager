# Tasks

## 1. Schema and server enforcement

- [x] 1.1 Ensure `lock_version` is enforced on PersistentEntryDraft and add unique `client_create_id` if missing; verify migration and model optimistic lock unit tests
- [x] 1.2 Update draft create to be idempotent on `client_create_id` and draft update/discard/final Save to reject stale versions with 409 (or equivalent) including current server payload; verify request tests for stale autosave, stale Save, stale discard, and lost-create retry dedupe
- [x] 1.3 Ensure PATCH/autosave after destroy returns 404/410 without inserting a new row; verify delayed autosave cannot resurrect finalized or discarded drafts

## 2. Client conflict UX

- [x] 2.1 Extend autosave Stimulus to send `lock_version` and `client_create_id`, handle 409 with Conflict detected status, stop silent overwrite, and provide Reload server version that replaces the editor while preserving local Markdown in a read-only copy surface; verify system/JS coverage for conflict reload behavior
- [x] 2.2 On 404/410 after finalize/discard, clear draft binding and halt retries without auto-creating a replacement; verify client behavior test

## 3. Baseline alignment verification

- [x] 3.1 Confirm Entry duplicate-submit remains frontend best-effort and Entry LWW tests still pass alongside draft conflict tests covering this change’s `entries` and `persistent-entry-drafts` deltas

## 4. Integration verification

- [x] 4.1 Run the draft concurrency suite (create idempotency, stale writes, no-resurrect, conflict UI) and spot-check autosave + multi-draft flows still pass

## Workflow follow-up

- Apply last in the dependent stack. After all four are applied and verified, archive in order so `openspec/specs/` reflects the merged persistent-drafts baseline.
