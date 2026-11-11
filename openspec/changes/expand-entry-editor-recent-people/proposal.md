# Proposal

## Why

Writing Entries is cramped: the Markdown body editor is short, and inserting `[[Person]]` references requires remembering and typing names. Expanding the Entry body editor and offering a Recent People quick-insert control will speed drafting without changing Save, validation, or person-resolution workflows.

## What Changes

- Double the visible vertical height of the Markdown body editor on New Entry and Edit Entry only (Person About editor height unchanged).
- Add a **Recent People** section immediately below the Save button on New Entry and Edit Entry.
- Show up to 20 unique People ranked by their most recent association to a saved Entry, newest first; exclude never-referenced People; no placeholders.
- Each name is an accessible button that inserts exactly `[[Person Name]]` into the Markdown body at the caret (or replaces the selection; appends if no usable selection), without submitting, navigating, or autosaving.
- Preserve OverType behavior, themes, toolbar, responsive layout, draft/session semantics, direct Save, and last-write-wins concurrency.
- **No BREAKING** API or data-model changes expected; schema migrations are out of scope unless investigation proves them necessary.

### Out of scope

- Autosave, autocomplete, chips, automatic linking UI, or rewriting typed wiki tokens into non-Markdown controls.
- Person About editor height or Recent People UI on Person pages.
- AI inference, multi-user, photos, calendar import/write, or reminder features.
- Changing wiki syntax, primary/secondary association rules, or the person-resolution workflow.

## Capabilities

### New Capabilities

- `recent-people-quick-insert`: Entry-form Recent People ranking, layout, accessibility, and insertion interaction for wiki person references.

### Modified Capabilities

- `markdown-editor`: Entry body editor visible height roughly doubles; the “no graphical wiki enhancements” boundary is revised so Entry pages MAY expose Recent People insert buttons while typed `[[Person]]` content remains literal Markdown and Person About stays free of that UI.

## Impact

- Views: `entries/new`, `entries/edit`, shared markdown editor partial/CSS (Entry-scoped height).
- Stimulus/JS: `markdown_editor_controller` and/or a companion controller for caret tracking and insert; OverType 2.7.0 selection/insert APIs.
- Backend: EntriesController (or a small query/service) to supply up to 20 recently referenced People via existing `entry_people` / `entries` associations—no new persistence expected.
- Tests: entries controller/system coverage, markdown editor JS tests, any person-association query unit tests.
- Baseline specs: new `recent-people-quick-insert`; delta to `markdown-editor`.
