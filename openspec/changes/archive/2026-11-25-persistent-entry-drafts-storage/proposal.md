# Proposal

## Why

Production CookieOverflow showed that staging a full Entry draft (including long Markdown) in the Rails CookieStore session is not viable. Unfinished drafts must live in SQLite as first-class server records so person resolution and later autosave/multi-draft work can scale without cookie limits or session affinity.

## What Changes

- Introduce durable unfinished Entry drafts in the existing SQLite database, separate from committed Entries.
- Keep the domain `EntryDraft` validation object; back it with an ActiveRecord draft row for persistence.
- Stop serializing full draft payloads into the session cookie; retain CookieStore for ordinary session/flash only.
- Key Preview and person-resolution actions by draft identity instead of `session[:entry_draft]`.
- On explicit Save: upsert the persistent draft as needed; persist via `EntrySaver` when valid; keep the draft through unresolved-person and validation-failure paths; destroy the draft atomically after successful Entry persistence.
- Filter journal Markdown / draft body parameters from production logs.
- **BREAKING (cutover):** Any in-progress cookie-staged session draft is abandoned at deploy; operators should finish or discard resolution before upgrading.
- Out of scope for this change: autosave, multi-draft UX, Config draft list, floating MRU resume redesign, optimistic locking/conflict UI, browser-local draft storage, Redis, Person About drafts, real-time collaboration.

## Capabilities

### New Capabilities
- `persistent-entry-drafts`: Durable unfinished Entry drafts stored in SQLite, isolated from committed Entries, addressable for Save and person resolution.

### Modified Capabilities
- `entries`: Replace session-cookie draft staging with persistent draft identity for resolution and post-resolution Save; remove the “no draft tables” / single-session-draft storage constraint for this foundation.
- `person-references`: Bind unknown/ambiguous resolution actions to a persistent draft identity while preserving existing resolution outcomes.
- `deployment`: Document SQLite draft table migration, cookie-draft cutover, and Markdown/draft log filtering; reaffirm no Redis requirement.
- `markdown-editor`: Long Markdown must survive Save → resolution without cookie overflow while remaining exact raw Markdown.

## Impact

- Schema: new `entry_drafts` table and migration on the production SQLite file.
- Controllers: `EntriesController` create/update/preview/resolution/discard paths; ApplicationController draft presence helper.
- Views: Preview/drafts links and forms carry draft identity; New/Edit may expose draft id when a draft already exists.
- Models/services: new AR draft model; `EntryDraft` gains record load/save helpers without becoming AR itself; `EntrySaver` success path deletes the matching draft transactionally where feasible.
- Tests: CookieOverflow regression with large bodies; resolution and Save against draft rows; Entry query isolation.
- Follow-on changes: `entry-draft-autosave`, `entry-draft-multi-and-management`, `entry-draft-concurrency`.
