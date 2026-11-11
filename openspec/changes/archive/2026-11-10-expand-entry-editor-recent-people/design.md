# Design

## Context

See `proposal.md` for motivation. Today:

- Entry new/edit forms share `shared/markdown_editor_field` and Stimulus `markdown-editor`, which progressively enhances a native textarea with vendored OverType 2.7.0 (`getValue` / `setValue` / `destroy` today).
- Visible editor height is CSS `min-height: 12rem` on `.markdown-editor-mount` / OverType containers, shared with Person About.
- Saved Person associations already live in `entry_people` joined to `entries` (`recent_first` = `occurred_on DESC, created_at DESC`). Wiki parsing and Save/resolution remain authoritative for persistence; this change only inserts literal Markdown.
- Baseline `markdown-editor` previously forbade graphical wiki helpers; the delta carves out Entry-only Recent People insert buttons.

## Goals / Non-Goals

**Goals:**

- Roughly double Entry body editor height without changing Person About height.
- Server-render up to 20 recently referenced People below Save; client inserts exact `[[Name]]` into the body form value OverType/Rails already submit.
- Keep Pi/SQLite-friendly queries; avoid schema changes and duplicate wiki parsers.

**Non-Goals:**

- Autosave, optimistic locking, or session-draft redesign.
- Autocomplete, chips, or live person search.
- Re-ranking while the form is open (static list per page load is enough).
- Changing primary/secondary association rules or resolution UI.

## Decisions

### 1. Scope height increase to Entry forms only
**Choice:** Double via Entry-scoped CSS (for example `.entry-form .markdown-editor-mount` and matching OverType/fallback rules) from ~`12rem` to ~`24rem`, leaving shared Person About styles alone. Optionally pass a height/size hint from Entry views if a class on the form is cleaner than a global selector.
**Why:** Spec requires Entry-only doubling; About and body currently share the same height rules.
**Alternatives:** Global `12rem` → `24rem` (would enlarge About); change `rows` alone (OverType height is CSS-driven more than rows).

### 2. Rank via `entry_people` + Entry chronology, not Markdown re-scan
**Choice:** Query distinct People who appear in `entry_people`, ordered by each Person's latest associated Entry using the same chronology as `Entry.recent_first` (`occurred_on DESC`, then `created_at DESC`). Limit 20. Use stored `people.name` for labels and insert text. Exclude People with zero associations automatically.
**Why:** Associations already reflect saved `[[Person]]` references after successful Save; SQLite-friendly; no schema change; reuses Person records as the only valid name source.
**Alternatives:** Scan all `body_markdown` with `WikiPersonParser` (slower, duplicates logic); rank by `entries.updated_at` (save time, not journal date); denormalize a `last_referenced_at` column (premature without evidence).

### 3. Placement and empty state
**Choice:** Render Recent People immediately after the Save submit control on both Entry forms (shared partial). When the list is empty, omit the section entirely (no empty-state copy, no placeholders).
**Why:** Matches requested placement; empty omit is quieter than a stub grid.
**Alternatives:** Minimal “No recent people” copy; place above Save (harder reach after writing).

### 4. Buttons + Stimulus insert bridge to OverType
**Choice:** Render `<button type="button">` controls (not links) with `data-person-name` (or equivalent). Prefer extending `markdown-editor` or a thin companion Stimulus controller owned by the Entry form that: (a) tracks last caret/selection on the OverType textarea via `selectionchange` / blur, (b) on `mousedown`/`pointerdown` calls `preventDefault` so the button does not clear selection before click, (c) inserts `[[Name]]` via OverType APIs if available, else native textarea `setRangeText` / value splice, (d) syncs so the named `entry[body_markdown]` field reflects the new value. Verify OverType 2.7.0 selection/insert helpers during apply; fall back to operating on the underlying textarea OverType owns if needed.
**Why:** Meets caret/selection/append rules without form submit; keeps one Markdown field of truth.
**Alternatives:** `document.execCommand('insertText')` only (fragile); put buttons outside any form controller (harder to reach editor instance).

### 5. No autosave / no schema
**Choice:** Insert only mutates client-side Markdown until existing Save. Do not add tables, columns, or draft IDs.
**Why:** Proposal and entries baseline already define direct Save, session draft for resolution only, and last-write-wins.
**Alternatives:** Persist click telemetry (out of scope).

### 6. Mobile and a11y
**Choice:** CSS grid ~4 columns on wide viewports; fewer columns on narrow; adequate min tap size; buttons have accessible names (visible Person name). Keep Recent People outside keyboard-trap concerns of the editor toolbar.
**Why:** Scenarios H and layout requirements; avoids accidental submit via `type="button"`.

## Risks / Trade-offs

- [OverType lacks stable selection/insert API] → Spike against vendored 2.7.0; fall back to the editor’s underlying textarea; keep exact `[[Name]]` splice semantics in tests.
- [mousedown preventDefault vs focus management] → Cover with JS/system tests that selection survives button press; ensure screen-reader activation still inserts.
- [Association lag vs unsaved typed refs] → Ranking uses saved associations only by design; unsaved draft mentions do not promote People until Save succeeds.
- [Name rename / slug mismatch] → Insert stored `Person.name` so Save’s existing resolver matches the same canonical name.
- [CSS doubles About by mistake] → Gate height under `.entry-form` (or Entry-only class); assert About height unchanged in a view/CSS test or manual check.
- [Pi performance on large journals] → Prefer one aggregated SQL query with limit; avoid N+1 and full-table Markdown scans.

## Migration Plan

- Deploy is additive front-end + query/partial; no data migration.
- Rollback: revert views/CSS/JS/controller query; existing Entries and associations untouched.

## Open Questions

- Exact OverType 2.7.0 method names for selection restore/insert (confirm against vendored build at apply; does not change specs).
- Whether a tiny shared Ruby query object vs inline controller helper is preferred (implementation detail only).
