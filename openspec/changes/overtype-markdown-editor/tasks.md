# Tasks

## 1. Vendor OverType and page-local importmap

- [x] 1.1 Vendor OverType **2.7.0** (re-verify checksum/version at apply) under `vendor/javascript`, preferring the ESM build for importmap + browser ES modules; pin the exact version in `config/importmap.rb` and verify a dynamic `import()` resolves without CDN
- [x] 1.2 Ensure nothing in `application.js` eagerly imports or preloads OverType; verify homepage load does not fetch/execute the OverType module while New Entry does load it when the editor mounts

## 2. Shared Stimulus Markdown editor

- [x] 2.1 Implement a Stimulus controller that dynamically imports OverType, initializes one instance per mount with toolbar (bold, italic, headings, lists, link) and keyboard shortcuts, maps light/dark theme, and destroys on disconnect; verify repeated Home ↔ New Entry navigation leaves exactly one instance per mount and no duplicate handlers
- [x] 2.2 Investigate Turbo snapshot behavior and add `turbo:before-cache` handling if cached pages retain OverType chrome; verify New Entry → Preview → Back and Edit Entry → Preview → Back keep a single healthy editor and do not lose unsaved Markdown beyond normal browser/Turbo form restoration
- [x] 2.3 Wire a single authoritative named field (`entry[body_markdown]` / `person[about_markdown]`) with existing `required` semantics and a native-textarea fallback if OverType init fails; verify only one named Markdown field submits and empty required body still fails client-side as today
- [x] 2.4 Add minimal CSS so editor size roughly matches the prior textarea and avoids horizontal overflow; verify New Entry and Person About on desktop and a narrow viewport

## 3. Wire Entry New/Edit forms

- [x] 3.1 Enhance New Entry and Edit Entry body fields with the shared editor while keeping labels, date field, hints, Preview submit targets, and Preview → Save workflow unchanged; verify both pages still POST to existing Preview actions
- [x] 3.2 Add/extend tests or scripted checks for Preview submission of editor Markdown, `[[Person]]` / `#tag` preservation, and **exact** no-op Edit → Preview string equality (including trailing newlines) against the initial browser-side value; verify affected `bin/rails test` entry suites stay green

## 4. Wire Person About

- [x] 4.1 Enhance About with the shared editor while **keeping** the existing About Preview toggle and Save About control; verify Preview toggle still reflects the authoritative textarea value and About PATCH still submits Markdown
- [x] 4.2 Verify failed About validation re-renders with content restored into the editor field; extend people controller/system coverage as needed and keep existing people tests green

## 5. Integration checks

- [x] 5.1 Confirm light and dark themes yield a usable editor on New Entry and Person About against `markdown-editor` theme scenarios and baseline `themes`
- [x] 5.2 Confirm Entry Preview → Save still stages then persists only on explicit Save; verify existing preview/save-banner controller expectations still pass
- [x] 5.3 Smoke exact no-op preservation and Turbo Back paths once more after full wiring; treat OverType init-time normalization (if any) as a blocker to fix or escalate before archive

## Workflow follow-up

- Archive this change after implementation review so `openspec/specs/markdown-editor/spec.md` becomes the main capability baseline.
- After archive, confirm `openspec validate --all --strict` still passes.
- Direct Entry save (skip mandatory Preview) remains a separate change (`direct-entry-save`), not part of apply for this change.
