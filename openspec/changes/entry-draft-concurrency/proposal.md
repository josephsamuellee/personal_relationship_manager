# Proposal

## Why

Persistent drafts are shared across devices under PRM’s single-user access boundary. Without revision checks, a delayed autosave or Save from a stale tab can silently overwrite newer server content or resurrect a finalized/discarded draft. Cross-device editing needs conflict detection without collaborative merging.

## What Changes

- Enforce optimistic revision control on unfinished drafts (`lock_version` or equivalent).
- Stale autosave, final Save, and Discard MUST NOT silently overwrite or delete a newer server revision; return a conflict outcome.
- On conflict, keep the rejected editor’s local Markdown available; offer reload of server version that replaces the editor while preserving local text in a read-only copy surface (approved §11).
- Idempotent first create via client-generated create id so lost create responses do not duplicate drafts.
- Delayed autosave MUST NOT recreate drafts that were finalized or discarded.
- Amend baseline wording that forbade new DB columns solely for duplicate-submit protection where it conflicts with draft revision/idempotency columns (draft-scoped only; Entry Save duplicate protection remains best-effort frontend).
- Out of scope: OT/CRDT, automatic Markdown merge, real-time collaboration, multi-user accounts, Redis, Person About concurrency.

## Capabilities

### New Capabilities
- _(none)_ — concurrency extends `persistent-entry-drafts`.

### Modified Capabilities
- `persistent-entry-drafts`: Conflict detection, recovery UX, create idempotency, no-resurrect rules.
- `entries`: Clarify that Entry last-write-wins remains for committed Entries, while unfinished drafts use optimistic conflict detection; adjust duplicate-submit requirement so draft revision/idempotency columns are allowed.

## Impact

- Depends on storage, autosave, and multi-management behaviors.
- Draft API returns 409 with server revision payload; Stimulus shows Conflict detected status and recovery UI.
- Migration for `client_create_id` if not already present; ensure `lock_version` enforced.
- Tests for stale autosave/Save/Discard, lost create response, post-finalize autosave, conflict reload UX.
