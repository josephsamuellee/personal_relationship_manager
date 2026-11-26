# Design

## Context

See proposal.md — Why. Today `EntriesController` stages `session[:entry_draft] = draft.to_session` for Preview and unresolved Save, which overflows CookieStore (~4 KB). `EntryDraft` is an ActiveModel domain object; `EntrySaver` persists valid drafts to `entries`. CookieStore remains the default session store. Follow-on changes add autosave, multi-draft management, and concurrency. Specs live under `specs/persistent-entry-drafts/`, `specs/entries/`, `specs/person-references/`, `specs/deployment/`, and `specs/markdown-editor/`.

## Goals / Non-Goals

**Goals**
- Persist unfinished drafts in SQLite with explicit columns (not opaque session blobs).
- Keep `EntryDraft` as the parse/validate/resolve object loaded from params or a draft row.
- Route Preview/resolution/discard/Save-after-resolution by draft id.
- Remove full draft payloads from the session cookie; keep CookieStore for flash/session.
- Transactionally destroy the draft after successful `EntrySaver.save!`.
- Filter Markdown/draft body params from logs.

**Non-Goals**
- Autosave, Stimulus status UI, debounce, navigation guards (next change).
- Multiple New drafts UX, Config list, floating MRU redesign (later change).
- Optimistic locking / conflict UI / create idempotency (later change) — schema MAY include `lock_version` as a forward-compatible column without enforcing conflicts yet.
- Replacing CookieStore with ActiveRecord sessions; Redis; Person About drafts.

## Decisions

### 1. Separate AR model + keep EntryDraft domain object
**Choice:** Add `PersistentEntryDraft` (table `entry_drafts`). `EntryDraft.from_record` / record upsert helpers bridge storage ↔ domain. Do not make `EntryDraft` an ActiveRecord model and do not store unfinished work in `entries`.  
**Why:** Avoids conflating committed Entries with drafts; keeps parsers testable; matches product isolation rules.  
**Alternatives:** AR session store for all sessions (rejected — product wants dedicated drafts and CookieStore retained); serialize entire `EntryDraft` as one JSON blob column (rejected — less inspectable; harder partial updates).

### 2. Schema (storage foundation)
**Choice:** Columns: `id`, nullable `entry_id` (FK to `entries`, `on_delete: :nullify`), `title`, `raw_date`, `body_markdown` (text, default `""`), `person_selections` (JSON text), `content_updated_at`, timestamps. Unique index on `entry_id` where present (at most one edit draft per Entry — enforced early for integrity). Include `lock_version` default 0 and nullable unique `client_create_id` as unused placeholders for the concurrency change so later migrations stay additive-only if desired; if preferring minimal schema now, omit them and add in `entry-draft-concurrency`. **Prefer including `lock_version` now** (Rails-friendly) and defer `client_create_id` to the concurrency change.  
**Why:** Matches approved field retention; unique edit-draft constraint prevents duplicate edit rows before multi-UX ships.  
**Alternatives:** No unique on `entry_id` until multi change (risks duplicates during storage-only phase).

### 3. When rows are created in this phase (no autosave yet)
**Choice:** Upsert a durable draft when Save (or legacy preview staging) needs staging: unresolved people path always; validation-only re-render upserts when a `draft_id` is already present on the form, and SHOULD upsert on unresolved/validation staging so content survives navigation. Happy-path valid Save with no existing draft need not create a row. Discard deletes the row.  
**Why:** Fixes CookieOverflow on the production failure path without requiring autosave yet.  
**Alternatives:** Always create a draft on every Save attempt (extra rows for happy path).

### 4. Request/URL identity
**Choice:** Preview and resolution routes accept `draft_id` (query or route param). Editor forms include hidden `entry[draft_id]` when a draft exists. Floating “Drafts” control may continue to list/resume the single most relevant draft via DB until the multi-management change redesigns it; presence checks query `entry_drafts` instead of `session[:entry_draft]`. Stop writing `session[:entry_draft]`.  
**Why:** Server-owned identity; cookie stays small.  
**Alternatives:** Keep draft blob in session (rejected).

### 5. EntrySaver + draft destruction
**Choice:** After successful `EntrySaver.save!`, destroy the associated `PersistentEntryDraft` inside the same DB transaction when a draft id is known (extend saver or wrap in controller transaction).  
**Why:** Spec requires cleanup with persistence.  
**Alternatives:** Delete after commit outside transaction (risks orphan draft on crash between commit and delete).

### 6. Deleted Entry under edit draft
**Choice:** FK `on_delete: :nullify`. Loading a draft whose `entry_id` was nullified shows a banner; final Save creates a **new** Entry only after explicit user confirmation (storage phase: show banner + block silent recreate until confirm param/UI). Full confirm UX may be completed in multi-management if needed; schema/nullify lands here.  
**Why:** Matches approved §11 decision.  
**Alternatives:** Restrict delete of Entries that have drafts (no Entry destroy UI today).

### 7. Logging
**Choice:** Add `body_markdown`, `:body`, and nested `entry.body_markdown` style keys to `filter_parameters`.  
**Why:** Privacy for journal content on Pi logs.

## Risks / Trade-offs

- [Cookie drafts lost at cutover] → Document; single-user impact; no automated migration of CookieStore blobs.  
- [Hidden draft_id missing on old cached forms] → Treat as new staging create; acceptable.  
- [Unique entry_id blocks two edit drafts] → Intended; multi change keeps one edit draft per Entry.  
- [Validation-only path without draft_id still memory-only until navigate] → Acceptable until autosave; unresolved path always persists.  
- [SQLite writes on each stage] → Low frequency without autosave; fine on Pi.

## Migration Plan

1. Add migration for `entry_drafts`; deploy `db:migrate` on persistent `DATABASE_PATH`.  
2. Ship controller/view changes that stop session draft payloads.  
3. Restart Puma.  
4. Rollback: revert app code; table may remain empty/unused or be dropped with draft data loss — do not drop casually in production without notice.  
5. Do not migrate cookie session drafts.

## Open Questions

None material for this phase; autosave URL replaceState, multi-draft UX, and conflict handling are deferred to dependent changes with approved product decisions.
