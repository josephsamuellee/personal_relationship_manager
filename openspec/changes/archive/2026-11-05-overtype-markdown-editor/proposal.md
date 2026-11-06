# Proposal

## Why

Entry and Person about Markdown are edited through plain textareas, so formatting requires memorizing syntax and offers little visual feedback. OverType provides a lightweight textarea-based editor with toolbar and keyboard shortcuts while keeping raw Markdown as the submitted value, improving authoring without changing persistence or the Entry Preview → Save workflow.

## What Changes

- Enhance the New Entry and Edit Entry `entry[body_markdown]` field with OverType (toolbar + keyboard shortcuts; Markdown syntax remains visible), preserving native form field names and required-field behavior.
- Enhance the Person about `about_markdown` field with the same OverType integration; **keep** existing About Preview toggle, Save About PATCH, validation errors, and content restoration after failed submission.
- Vendor an **exact tested OverType version** locally; pin it for importmap/ES module use; load the library only on pages that mount an editor (no eager import on unrelated pages).
- Map the editor theme to the existing application light/dark theme.
- Require **exact** no-op Markdown string preservation (including whitespace and trailing newlines) relative to the initial browser-side Markdown string; preserve `[[Person]]` and `#tag` tokens; do not normalize or re-serialize Markdown.
- Handle Turbo navigation lifecycle so editor instances do not duplicate, leak handlers, or lose unsaved Markdown across Preview/back and other navigations.
- Retain the current Entry Preview → Save session-draft workflow unchanged in this change.

## Capabilities

### New Capabilities
- `markdown-editor`: Shared OverType Markdown editing surface for Entry body and Person about fields, including toolbar/shortcuts, theme alignment, page-local loading, native form submission of raw Markdown, exact no-op preservation, Turbo-safe lifecycle, and preservation of wiki-link and hashtag syntax.

### Modified Capabilities
- (none) — `entries` Preview → Save, `person-references`, `tags`, `themes`, and `date-parsing` baseline contracts remain in force; this change adds editor UI without altering those requirements. Direct Entry save (skipping mandatory Preview) is deferred to a separate change.

## Impact

- Views: `app/views/entries/new.html.erb`, `app/views/entries/edit.html.erb`, `app/views/people/show.html.erb` (about section); optional shared partial for the editor mount. About Preview control remains.
- JavaScript: new Stimulus controller(s); dynamic/page-local import of vendored OverType; Turbo connect/disconnect and, if needed, `turbo:before-cache` handling.
- CSS: thin layout/height overrides so the editor occupies roughly the current textarea footprint; theme bridging to OverType solar/cave or custom colors.
- Assets: exact-version vendored OverType build compatible with Rails importmap + browser ES modules; no CDN requirement for production; no eager global import.
- Backend: no controller, route, model, schema, parser, or `EntrySaver` changes in this change.
- Tests: Entry Preview and About submission of Markdown; exact no-op preservation; wiki/tag preservation; Turbo navigation / single-instance checks as feasible; existing Preview → Save tests remain green.
- Out of scope: direct Entry save, autosave, real-time person validation, Action Text, React/bundler migration, person/tag graphical enhancements, AI/multi-user/photo/calendar-write ideas.
