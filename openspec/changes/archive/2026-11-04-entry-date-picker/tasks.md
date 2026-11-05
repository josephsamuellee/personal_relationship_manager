# Tasks

## 1. Shared date field markup and layout

- [x] 1.1 Extract a shared Occurred On partial used by New Entry and Edit Entry with label, editable `entry[raw_date]` input, Use Today, Pick Date, and a container for picker/error UI; verify both pages render the same control structure
- [x] 1.2 Pass server-computed application-zone today into the partial/controller via data attribute; verify Use Today can read that value instead of relying only on browser local `Date`
- [x] 1.3 Add CSS for a compact horizontal `.occurred-on-row` with responsive wrap that does not cause horizontal page overflow; verify desktop one-line order and narrow wrap in browser or CSS review against the compact-layout scenarios

## 2. Client date parse helpers for picker open

- [x] 2.1 Implement JS parse helpers covering DateParser-supported unambiguous formats (DD MMM YYYY, DD-MMM-YYYY, YYYYMMDD, YYYY-MM-DD, YYYY-W##-D) and rejection of ambiguous slash dates; verify with unit tests mirroring key `DateParser` fixtures
- [x] 2.2 Wire Pick Date open to initialize view month/year from the current field text when parse succeeds, and to show a non-destructive error without overwriting the field when parse fails; verify historical, future, date-link, and invalid-text scenarios

## 3. ISO calendar UI and selection

- [x] 3.1 Render Monday-first calendar grid with month/year header, prev/next month controls, scrollable year dropdown, weekday headers Mon–Sun, and leftmost `W##` ISO week column (including year-boundary weeks); verify header/week/ISO scenarios
- [x] 3.2 Keep navigation (month arrows, year select) from mutating the occurred_on field until a day is chosen; verify browse-without-select scenarios
- [x] 3.3 Show muted adjacent-month days to complete weeks; selecting any day (including adjacent-month) writes `DD MMM YYYY` into the field, highlights selection on reopen, closes the picker, and does not submit/save; verify selection and adjacent-month scenarios
- [x] 3.4 Ensure reopening Pick Date re-initializes from the current field value rather than the last browsed month; verify reopen scenario

## 4. Use Today and shared-page consistency

- [x] 4.1 Update Use Today to set today's date from the server-provided app-zone value in `DD MMM YYYY` without saving; verify subsequent Pick Date opens today's month/year
- [x] 4.2 Confirm Edit Entry does not persist date changes until successful save/preview workflow; verify existing entry save tests still pass and edit draft behavior is unchanged for title/body/people/tags

## 5. Integration verification against baseline

- [x] 5.1 Run existing date-parser and entries controller/model tests and confirm no regressions to formats, validation, preview, or save (`bin/rails test` for affected files)
- [x] 5.2 Manually or with system tests verify Add Entry defaults to today, date-link prefill still works, and New/Edit both expose picker behavior per `entry-date-picker` scenarios

## Workflow follow-up

- Archive the change after implementation review so `openspec/specs/entry-date-picker/spec.md` becomes the main capability baseline.
- After archive, confirm `openspec validate --all --strict` still passes.
