# Tasks

## 1. Entry editor height

- [x] 1.1 Double Entry body Markdown editor visible height (~12rem → ~24rem) under Entry-form-scoped CSS only, leaving Person About height unchanged, and verify New/Edit Entry mounts look roughly twice as tall while Person About does not
- [x] 1.2 Confirm OverType toolbar, theme mapping, Turbo teardown, and fallback textarea still behave on Entry pages after the height change (smoke existing markdown editor controller/view coverage)

## 2. Recent People query and markup

- [x] 2.1 Add a SQLite-friendly query (controller helper or small object) that returns up to 20 unique People ordered by latest associated Entry `occurred_on`/`created_at`, excluding never-associated People, and verify unit/controller tests for ranking, uniqueness, limit, and empty results
- [x] 2.2 Load that list on New Entry and Edit Entry actions and render a shared Recent People partial immediately below Save using `type="button"` controls labeled with `Person.name` (omit section when empty); verify `get new_entry_path` / `get edit_entry_path` assertions for placement, button-not-link, count, and empty omit
- [x] 2.3 Style the grid for four columns / up to five rows on wide viewports and responsive touch-friendly columns on narrow viewports; verify CSS/layout against the desktop and mobile layout scenarios

## 3. Insert into Markdown body

- [x] 3.1 Spike OverType 2.7.0 selection/insert APIs on the vendored build and wire Stimulus (extend `markdown-editor` or companion) to track last caret/selection, preserve it across button `pointerdown`/`mousedown`, and insert exactly `[[Person Name]]` (replace selection; append if none); verify JS tests for caret insert, replace, append, and no extra whitespace
- [x] 3.2 Ensure inserted text updates the single submitted `entry[body_markdown]` field, does not touch title/date, does not submit/navigate/autosave, and verify controller/system coverage that Save persists inserted refs and that a click alone does not create/update an Entry
- [x] 3.3 Confirm Person About still has no Recent People UI and typed wiki links remain literal Markdown without required picker usage; verify people About tests and the revised markdown-editor scenarios remain green

## 4. Regression integration

- [x] 4.1 Run affected Rails and JS suites (entries controller/model/draft, markdown editor exact-value, people about) and verify direct Save, person-resolution fallback, draft/session behavior, last-write-wins, and no eager OverType import from `application.js`
- [x] 4.2 Manually or via system test exercise Scenario H on a narrow viewport (tap insert without submit) and Scenario I (edit existing Markdown, insert, save) and confirm acceptance scenarios A–I are covered by automated tests or an explicit checklist note in the PR/change notes

## Workflow follow-up

- Archive the change after implementation and review (`/opsx-archive` or equivalent).
- Confirm main specs under `openspec/specs/` include `recent-people-quick-insert` and the updated `markdown-editor` requirements.
