# Design

## Context

See proposal.md — Why. Entry New/Edit use plain `text_area_tag "entry[body_markdown]"` posting to Preview (`create_preview` / `create_preview_update`), which stages `session[:entry_draft]` before explicit Save via `EntrySaver`. Person About uses `form.text_area :about_markdown` with direct PATCH in `PeopleController#update` and Stimulus `about_editor_controller.js` for a client-side Preview toggle. The stack is importmap + Stimulus + Turbo with no npm bundler. Specs for this change live under `specs/markdown-editor/`.

## Goals / Non-Goals

**Goals**
- Integrate OverType as a page-local Stimulus-managed editor for Entry body and Person about.
- Submit raw Markdown through existing field names; keep Entry Preview → Save and About PATCH + About Preview toggle.
- Exact no-op Markdown string equality vs the initial browser-side string (no normalization).
- Turbo-safe lifecycle (single instance per mount; no handler leaks; no editor-caused loss of unsaved Markdown).
- Vendor an exact tested OverType build compatible with importmap + browser ES modules; load only when an editor mounts.

**Non-Goals**
- Direct Entry save (skip Preview) — separate future change.
- Autosave, real-time person validation, or new endpoints.
- Custom wiki/hashtag rendering, autocomplete, or chips.
- React, esbuild, or Action Text.
- Schema, model, parser, controller, route, or `EntrySaver` changes.

## Decisions

### 1. Library: OverType, exact pin, ESM-first for importmap
**Choice:** Vendor **OverType 2.7.0** (exact tested version at planning time; re-verify at apply). Prefer `overtype.esm.js` for `importmap` + dynamic `import()` from the Stimulus controller. Keep the IIFE `overtype.min.js` available only if ESM pinning fails verification.  
**Why:** Textarea-native Markdown minimizes rewrite risk; ~140KB is acceptable on editor pages; no bundler; exact pin avoids floating `latest`.  
**Alternatives:** CDN `latest` (rejected for Pi/offline and non-determinism); TOAST UI (heavier, higher round-trip risk).

### 2. Single source of truth + native fallback
**Choice:** Progressive enhancement around **one** authoritative Markdown control with the existing `name` / `required` attributes. On successful OverType init, that same logical field remains the only named submitter (OverType’s textarea with transferred `name`/`id`/`required`, or OverType attached such that the original named textarea is the editable surface). If OverType fails to initialize, the native textarea remains usable and is the sole named field. Never submit two named Markdown fields for the same input.  
**Why:** Preserves native validation and Preview/About semantics; meets “fallback if OverType fails” without dual sources of truth.  
**Alternatives:** Hidden sync field + `getValue()` on submit (dual truth risk); OverType-only with no fallback (weaker resilience).

### 3. Exact no-op preservation
**Choice:** Treat the Markdown string used to initialize the editor in the browser as the baseline. On unmodified submit, posted value MUST `===` that string (whitespace and trailing newlines included). Do not run Markdown parsers/serializers on the value for storage/submit. Rely on OverType’s `getValue()` / textarea `.value` identity.  
**Why:** Spec requires exact equality, not “practical” equality.  
**Note:** Server ERB → HTML entity decoding can already change what the browser sees vs DB bytes; the contract is browser-side init string ↔ submit string.

### 4. Lifecycle: Stimulus + Turbo cache investigation
**Choice:** `connect` → dynamic import (once per page need) → init; `disconnect` → `destroy()`. During apply, **verify whether `turbo:before-cache` handling is required**: Turbo caches DOM snapshots; a live OverType tree can restore as a broken/half-initialized editor. If snapshots retain OverType chrome, destroy (or reset to a clean native textarea state) on `turbo:before-cache` before the page is cached, then re-init on connect after restore. Preserve normal browser Back/forward form restoration behavior—do not invent a parallel draft store.  
**Why:** Spec scenarios cover New/Edit → Preview → Back and repeated editor/non-editor navigation.  
**Alternatives:** Ignore before-cache (risk of duplicate/orphan DOM); custom sessionStorage draft (out of scope).

### 5. Page-local loading
**Choice:** Pin OverType in importmap, but **do not** `import "overtype"` from `application.js`. Only the editor Stimulus controller dynamically imports it when a mount is present.  
**Why:** Satisfies page-local loading; pin alone does not download until imported.  
**Alternatives:** Script tag in layout (loads everywhere); CSS `preload` (rejected).

### 6. Theme
**Choice:** Map application dark → OverType `cave` (or custom dark), light → `solar` (or custom light) from `html[data-theme]` / server value. No separate editor theme setting.

### 7. Toolbar scope
**Choice:** Toolbar actions for bold, italic, headings, lists, and link; enable keyboard shortcuts; omit file upload and custom wiki/tag syntax processors. Optionally hide view-mode/tasks/code if they distract, as long as required actions remain.

### 8. About Preview retained
**Choice:** **Keep** the existing About Preview toggle and Save About control. Wire OverType so `about_editor_controller` continues to read the same authoritative textarea value for its preview toggle (update target wiring if the DOM wrapper changes). Do not remove or redesign About Preview.  
**Why:** Explicit product refinement; prior design that removed Preview is reversed.  
**Alternatives:** Remove Preview (rejected).

### 9. Shared partial
**Choice:** Optional shared ERB/Stimulus mount pattern for Entry body and About; Entry-only hint for `[[Person]]` / `#tag` stays on Entry forms.

## Risks / Trade-offs

- [Turbo cache restores broken OverType DOM] → Investigate and likely handle `turbo:before-cache`; destroy/reset before snapshot.  
- [Exact equality fails if OverType normalizes on init] → Spike no-op submit early; blocker if library rewrites unmodified values.  
- [Fallback vs OverType DOM ownership] → Implement transfer of `name` carefully so only one field submits.  
- [About Preview reads wrong node after wrap] → Keep `data-about-editor-target="textarea"` on the authoritative textarea.  
- [Line-start `#tag` looks like heading in overlay] → Overlay styling only; stored Markdown unchanged.  
- [ESM pin quirks with importmap] → Verify `overtype.esm.js` in Rails; fall back to documented compatible dist only if needed, still exact-version pinned.

## Migration Plan

1. Vendor OverType **2.7.0** (or the exact version re-verified at apply) and pin for ESM dynamic import.  
2. Ship Stimulus controller + CSS; wire New/Edit/About **without** removing About Preview.  
3. Verify Turbo Preview ↔ Back and homepage does not fetch OverType.  
4. Deploy as normal Rails/vendor assets; no DB migration.  
5. Rollback: revert views/JS/pin; data untouched.

## Open Questions

- Whether OverType 2.7.0’s ESM build needs a small importmap shim for secondary bare imports (verify at apply; pin any extra vendor files if required).  
- Whether trimming OverType’s view-mode control is desired for quieter UI (optional; not a spec blocker).
