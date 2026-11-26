# Proposal

## Why

With durable drafts and autosave, users will accumulate multiple unfinished New drafts and need a clear way to resume Edit drafts, jump to the most recent work from the floating control, and manage or discard drafts from Config—without mixing unfinished work into committed Entry surfaces.

## What Changes

- Support multiple independent New Entry unfinished drafts.
- Edit Entry automatically resumes the single unfinished draft for that Entry when one exists; at most one edit draft per committed Entry.
- Floating Drafts control resumes the most recently modified unfinished draft directly (by `content_updated_at`); hide when none exist. Reading/listing MUST NOT change MRU order.
- Config gains an Unfinished Drafts section: title/Untitled, occurrence date, last modified, New vs Edit, Resume, Discard with confirmation. No separate Drafts management page, trash, or auto-expiration.
- Opening New Entry always starts fresh; resume happens via floating control, Config, or draft editor URL.
- When the linked committed Entry was deleted, nullified drafts show a banner; Save creates a new Entry only after explicit confirmation.
- When the linked committed Entry changed while a draft exists, warn on resume and final Save but still allow Save to overwrite the Entry (existing last-write-wins for Entries).
- Retire the intermediate session-era Drafts landing page as the primary resume path (redirect or remove in favor of MRU editor / Config).
- Out of scope: autosave mechanics (prior change), optimistic-lock conflict UI (next change), Person About drafts, Redis, collaborative editing.

## Capabilities

### New Capabilities
- _(none)_ — management UX extends `persistent-entry-drafts` and `configuration`.

### Modified Capabilities
- `persistent-entry-drafts`: Multi-draft coexistence, MRU ordering rules, Edit resume, deleted/changed Entry handling, discard confirmation.
- `configuration`: Unfinished Drafts management section on Config.
- `application`: Floating Drafts control resumes MRU unfinished draft.
- `entries`: New always fresh; Edit resumes unfinished draft when present.

## Impact

- Depends on storage + autosave foundations.
- Config show/update views and possibly discard endpoint reuse.
- Floating controls helper queries MRU draft.
- Edit Entry controller loads existing draft by `entry_id`.
- Tests for multi New drafts, MRU floating, Config list/discard, read-without-bump, deleted Entry banner/confirm.
- Follow-on: `entry-draft-concurrency`.
