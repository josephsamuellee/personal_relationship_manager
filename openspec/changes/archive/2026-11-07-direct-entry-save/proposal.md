# Proposal

## Why

Creating or editing an Entry currently requires a mandatory Preview step even when every person reference already resolves and validation passes. That confirmation adds friction for routine journal entries without improving safety for the common case. Direct Save removes that step while keeping EntryDraft validation, person resolution, and EntrySaver persistence intact for exception paths.

## What Changes

- **BREAKING (workflow):** New Entry and Edit Entry replace the primary **Preview** control with a primary **Save** control. Valid drafts persist in that request without visiting Preview first.
- When Save encounters unknown or ambiguous person references, reuse the existing Preview/person-resolution UI (stage `session[:entry_draft]`, resolve, then Save). Do not invent a new resolution surface.
- When Save fails ordinary validation with all people recognized, prefer re-rendering New/Edit with errors and preserved submitted fields rather than Preview.
- Validation precedence: if both unresolved people and ordinary validation errors exist, show the existing Preview/resolution UI first while preserving and communicating the validation errors; do not persist until both succeed.
- Relationship add/remove/primary-order changes apply automatically on successful direct Save without a separate relationship-diff confirmation. The existing relationship-diff display MAY remain on the resolution UI but MUST NOT block valid direct saves.
- Reuse `EntryDraft` and `EntrySaver`; keep session-draft resolution Save (`create`/`update` from staged draft) working.
- Best-effort frontend duplicate-submit protection on Save; no server-side idempotency infrastructure.
- Preserve last-write-wins concurrent edits; document multi-tab session-draft interference as an accepted limitation.
- OverType continues to submit raw `entry[body_markdown]`; Person About editing is unchanged.
- Out of scope: autosave, real-time person validation, autocomplete/quick-insert, new resolution UI, schema/migrations, multi-draft session storage, optimistic locking, server idempotency tokens.

## Capabilities

### New Capabilities

- (none) — direct Save is Entry create/edit workflow behavior and belongs under existing `entries`, with editor-submission wording updates under `markdown-editor`.

### Modified Capabilities

- `entries`: Replace mandatory Preview-before-Save with direct Save as the primary path; revise explicit creation workflow, relationship-changing edits confirmation, and add requirements for resolution fallback, validation precedence, session-draft compatibility, duplicate-submit protection, and concurrent-edit semantics.
- `markdown-editor`: Stop requiring Preview as the mandatory New/Edit submission destination; align Entry form submission scenarios with Save while preserving raw Markdown submission, exact no-op preservation, wiki/tag preservation, Turbo lifecycle, and About Preview unchanged.

## Impact

- Controller: `EntriesController#create` and `#update` accept form params for direct Save (branch: unresolved → stage + resolution UI; valid → `EntrySaver`; validation-only errors → re-render New/Edit). Existing session-based Save from Preview remains.
- Routes: New/Edit forms post/patch to `entries_path` / `entry_path` instead of Preview collection/member preview actions; Preview routes remain for resolution and any remaining stage path.
- Views: `app/views/entries/new.html.erb`, `edit.html.erb` (Save button, form URL/method); Preview view reused for unresolved people; optional Turbo `data-turbo-submits-with` / disable-while-submitting on Save.
- Services/models: Prefer reusing `EntryDraft.from_params`, `valid_for_save?`, `unresolved_people`, and `EntrySaver.save!` without duplicating parsers or persistence.
- Tests: Controller integration coverage for direct create/update, unresolved → preview, validation re-render, resolution Save; update tests that assume Preview as the New/Edit submit target; keep markdown editor mount/no-op and About tests green.
- Specs: Baseline `openspec/specs/entries` and `markdown-editor` after archive must reflect direct Save.
- No schema, migration, or new dependencies.
