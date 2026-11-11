# Tasks

## 1. Dependencies and secret configuration

- [x] 1.1 Add the chosen Google OAuth/Calendar client dependency to the Gemfile, bundle install, and verify the app boots (`bin/rails runner 'puts :ok'`)
- [x] 1.2 Define externalized env/credential keys for Google OAuth client ID, client secret, and token storage path/strategy (no secrets in git); update `.env.example` and verify example keys are documented without real values
- [x] 1.3 Mark `GOOGLE_CALENDAR_EMBED_URL` obsolete in README configuration tables and verify docs no longer present the iframe URL as required for Upcoming Calendar

## 2. Date range, normalization, and grouping

- [x] 2.1 Implement two-ISO-week range calculation from `Time.zone.today` (current week Monday–Sunday + next week) and verify unit tests for 2026-11-07 → W45/W46 and 2026-12-31 → 2026-W53/2027-W01
- [x] 2.2 Implement normalized external-event value object plus all-day exclusive-end and timed multi-day overlap day assignment in `Time.zone`; verify unit tests for all-day, Taiwan→LA crossover, DST, and multi-day span scenarios from `upcoming-calendar`
- [x] 2.3 Implement cancelled-event exclusion and identity-based dedupe across calendars; verify unit tests that title+date alone does not dedupe and shared reliable identity does

## 3. Settings allowlist and OAuth connection

- [x] 3.1 Add an additive reversible `settings` migration for the calendar allowlist (non-secret) and Setting helpers; verify migrate/rollback and model tests for empty/multi-id allowlists
- [x] 3.2 Implement server-side OAuth connect, callback, token persistence (encrypted/non-UI), and disconnect; verify tokens never appear in Config HTML and disconnect clears usable auth (request/controller tests with stubs)
- [x] 3.3 Add Config UI for connection status, Connect/Disconnect, and calendar allowlist multi-select when connected; verify configuration scenarios (disconnected, reconnect-required, save/clear allowlist) via controller/system assertions

## 4. Read-only event fetch API

- [x] 4.1 Implement server-side Google calendar list + events fetch for the two-week window with read-only scopes, `singleEvents` recurrence expansion, and allowlist filtering; verify stubbed service tests for allowlist A+C, empty allowlist, recurring Wednesdays, and cancelled exclusion
- [x] 4.2 Add a same-origin JSON (or HTML frame) events endpoint that returns normalized day-grouped titles/metadata only (no descriptions/locations/attendees/tokens); verify request tests for success, timeout/API failure, and reauthorization-required payloads without secret leakage
- [x] 4.3 Ensure homepage show action does not call Google synchronously; verify homepage controller test still passes quickly with Google stubbed unavailable and non-calendar sections present

## 5. Upcoming Calendar grid UI

- [x] 5.1 Replace the homepage iframe with the two-week Upcoming Calendar grid shell (W##, Mon–Sun, zero-padded days, red today outline, past days visible, stable min-height); verify homepage rendering scenarios 1.1/1.2-style assertions and theme-safe today outline
- [x] 5.2 Add Stimulus (or Turbo) client to fetch events asynchronously, show subtle loading, populate up to three event chips per day, and reveal `+N more` without leaving homepage; verify overflow and slow-response behavior with fixture JSON / system test stubs
- [x] 5.3 Wire graceful unavailable/error/reconnect UI states and Turbo-safe stale-response ignoring; verify failure and navigation-during-loading scenarios do not duplicate chips or expose credentials
- [x] 5.4 Ensure narrow-viewport usability (seven weekdays identifiable, chips activatable); verify with a responsive CSS check or system assertion on a narrow viewport

## 6. New Entry seeding from calendar

- [x] 6.1 Extend New Entry to accept an optional body seed param when no overriding session draft exists, preserving existing `occurred_on` ISO init; verify entries scenarios for seeded body, special characters, non-persist on navigate-away, and validation failure retaining date/body
- [x] 6.2 Link day cells to New Entry with date only (empty body) and event chips to New Entry with cell date + exact title; verify click-through scenarios including multi-day cell date 13 November → `Family Vacation`

## 7. Documentation and integration verification

- [x] 7.1 Document Google Cloud OAuth client setup, read-only scopes, Cloudflare Tunnel HTTPS redirect URI, allowlist Config steps, and Pi env vars in README; verify the documented redirect-host guidance matches the `deployment` OAuth callback requirement
- [x] 7.2 Run the focused test suite for calendar normalization, OAuth/config, events endpoint, homepage grid, and Entry seeding (`bin/rails test` for the touched test files) and verify failures are fixed before calling the change implementation-complete
- [x] 7.3 Manually smoke-check against `upcoming-calendar` / `homepage` / `configuration` / `entries` / `deployment` acceptance scenarios on a connected stub or real Google sandbox and record any remaining gaps

## Workflow follow-up

- Archive the change with `/opsx-archive` after review and implementation are complete.
- Confirm main specs under `openspec/specs/` reflect the merged baseline after archive.
