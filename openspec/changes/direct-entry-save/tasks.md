# Tasks

## 1. Backend Save branching

- [x] 1.1 Refactor `EntriesController#create` and `#update` to build an `EntryDraft` from submitted `entry` params when present, otherwise from `session[:entry_draft]`, and verify with a controller test that resolution Save without body params still persists a previously staged valid draft
- [x] 1.2 Implement unresolved-people branch: stage `session[:entry_draft]`, redirect to existing Preview/resolution UI with existing notice helpers, do not call `EntrySaver`, and verify unknown and ambiguous wiki references on New and Edit Save redirect to preview without creating/updating Entries
- [x] 1.3 Implement happy-path branch: when `valid_for_save?`, call `EntrySaver.save!`, clear `session[:entry_draft]`, redirect to Entry detail with existing success notices, and verify a single POST create and PATCH update persist exactly once and clear the session draft
- [x] 1.4 Implement validation-only failure branch (no unresolved people): re-render `:new` or `:edit` with `@draft` and errors (unprocessable), preserve submitted fields, and verify missing title/person and invalid date cases do not persist and redisplay the form
- [x] 1.5 Cover validation precedence: Save with unknown person plus invalid date stages and shows Preview/resolution with the date error preserved, without persistence; verify via controller test against `entries` precedence scenarios

## 2. Form and UI changes

- [x] 2.1 Point New Entry form at `entries_path` POST with primary **Save** (no Preview button), keep OverType `entry[body_markdown]` field, and verify `get new_entry_path` shows Save and posts to create
- [x] 2.2 Point Edit Entry form at `entry_path` PATCH with primary **Save** (no Preview button), keep `entry[entry_id]`, and verify edit page Save updates via direct PATCH
- [x] 2.3 Add best-effort Turbo submit disable / `data-turbo-submits-with` (or equivalent) on New/Edit Save without disabling Turbo globally, and verify the Save control exposes a saving/disabled state attribute under supported Turbo behavior
- [x] 2.4 Confirm relationship-diff still appears only on Preview/resolution for edit drafts when associations change, and that a valid direct Save adding/removing a recognized person applies associations without visiting Preview; verify with controller or model-level assertions on `entry_people`

## 3. Compatibility and editor regression

- [x] 3.1 Keep Preview resolution actions (`resolve_person`, `create_person`, `replace_person_name`, discard) and Preview Save working for staged drafts; verify create-person then Save persists and clears the draft
- [x] 3.2 Update tests that assumed New/Edit → Preview → Save (including save-banner and no-op Markdown preservation) to use direct Save while asserting exact `body_markdown`, wiki links, and hashtags are unchanged; verify `bin/rails test test/controllers/entries_controller_test.rb` and related entry tests pass
- [x] 3.3 Confirm Person About Preview toggle and About save remain unchanged and OverType is still not eagerly imported from `application.js`; verify people controller markdown tests and the existing application.js assertion stay green

## 4. Integration checks

- [x] 4.1 Run affected suites (`bin/rails test` for entries controller/model/draft and people about editor coverage) and confirm direct Save, resolution fallback, validation re-render, and session resolution Save scenarios from the `entries` and `markdown-editor` deltas pass
- [x] 4.2 Manually smoke New Entry happy path, unknown-person → resolve → Save, validation failure re-render with Markdown restored, and browser Back from resolution where feasible; confirm no schema migrations were introduced

## Workflow follow-up

- Archive this change after implementation review so main `openspec/specs/entries` and `markdown-editor` reflect direct Save.
- After archive, confirm `openspec validate --all --strict` still passes.
