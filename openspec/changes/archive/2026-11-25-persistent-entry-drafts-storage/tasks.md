# Tasks

## 1. Schema and domain bridge

- [x] 1.1 Add `entry_drafts` migration (`entry_id` nullable FK nullify, title, raw_date, body_markdown, person_selections JSON, content_updated_at, lock_version, timestamps; unique index on `entry_id` where present) and verify with `bin/rails db:migrate` in test/dev plus schema presence assertions
- [x] 1.2 Implement `PersistentEntryDraft` ActiveRecord model with JSON `person_selections`, optimistic `lock_version` column present, and helpers to build/update from Entry form attrs; verify model unit tests for round-trip of title/raw_date/body/selections without creating Entry/Person rows
- [x] 1.3 Add `EntryDraft` load/bridge from a persistent record (re-parse/validate on load) and verify existing `EntryDraft` parser tests still pass plus a from-record reparse test

## 2. Controller Save and resolution by draft id

- [x] 2.1 Stop writing `session[:entry_draft]` full payloads; upsert durable drafts on unresolved Save and legacy preview staging; pass `draft_id` through Preview/resolution; verify unknown/ambiguous Save creates a DB draft, redirects to Preview, and leaves Entry count unchanged
- [x] 2.2 Update `resolve_person`, `create_person`, `replace_person_name`, `show_preview`, and discard to load/update/delete by draft id; verify resolution then Save persists Entry and removes only that draft row
- [x] 2.3 On valid Save, destroy associated draft inside the same transaction as `EntrySaver.save!` when a draft id is present; verify success clears the draft and failure leaves no partial Entry associations (existing transactional scenarios)
- [x] 2.4 Change draft presence helper / floating Drafts visibility to query unfinished draft rows instead of session; verify control appears when a DB draft exists and hide when none remain after discard/Save

## 3. Long Markdown, logging, and isolation

- [x] 3.1 Add request-level regression covering ~4 KB unresolved Save that previously CookieOverflowed: assert success path stages durable draft without cookie overflow, and cover 1/16/64 KB plus Traditional Chinese exact body retention through resolution Save
- [x] 3.2 Filter `body_markdown` / nested entry body params in `filter_parameters`; verify a controller or logging assertion that filtered output does not contain the full submitted body
- [x] 3.3 Verify unfinished drafts do not appear in Entry search / homepage timeline fixtures (or equivalent query tests) while a matching draft title/body exists only on `entry_drafts`

## 4. Integration verification

- [x] 4.1 Run entries controller, entry draft/model, and related suites; confirm direct Save happy path, validation-only re-render, resolution fallback, discard, and CookieOverflow regressions all pass against `openspec/changes/persistent-entry-drafts-storage/specs/` scenarios

## Workflow follow-up

- Archive after apply when ready; then implement dependent changes `entry-draft-autosave`, `entry-draft-multi-and-management`, and `entry-draft-concurrency` in order (or apply them against this foundation without archiving if working as a stack).
