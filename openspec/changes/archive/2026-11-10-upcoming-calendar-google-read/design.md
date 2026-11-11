# Design

## Context

See proposal.md for motivation. Current homepage renders Upcoming Calendar as an iframe via `EmbedCalendarProvider` + `GOOGLE_CALENDAR_EMBED_URL`. `APP_TIME_ZONE` already drives `config.time_zone` / `Time.zone`. New Entry already accepts `occurred_on` (ISO date) but does not seed `body_markdown`. Config uses a single-row `settings` table for theme/favorites; deployment forbids storing calendar secrets as ordinary editable Config fields. Production is single-user Rails + SQLite on a Pi, often reached via LAN HTTP and Cloudflare Tunnel HTTPS. No Google API gems exist yet. No Redis/Sidekiq.

## Goals / Non-Goals

**Goals:**
- Native two-ISO-week grid with async Google event population
- Read-only OAuth + Calendar API behind a server-side boundary
- Config UX for connect/disconnect and calendar allowlist
- Reuse New Entry for date/event clicks with safe title seeding
- Pi-appropriate: no background sync, no event tables, minimal deps

**Non-Goals:**
- Person matching, TODOs, follow-ups, auto-persist, calendar write
- General calendar framework or Entry schema changes for external events
- Persistent Google event cache presented as synchronized truth

## Decisions

### 1. Capability shape
**Choice:** New `upcoming-calendar` capability (parallel to `recent-timeline`), with deltas on `homepage`, `configuration`, `entries`, and `deployment`.

**Why:** Recent Timeline already owns retrospective homepage behavior as its own capability; Upcoming Calendar is the prospective counterpart and will grow later without bloating `homepage`.

### 2. Replace iframe; retire embed URL
**Choice:** Remove iframe as primary presentation. Stop requiring `GOOGLE_CALENDAR_EMBED_URL`. Keep a short README migration note.

**Alternatives:** Keep iframe as fallback when API disconnected — rejected because it reintroduces the wrong product question and unstable layout.

### 3. Google auth: OAuth 2.0 authorization code + refresh token
**Choice:** Web OAuth client with scopes limited to calendar list + events read. Register redirect URI on the Cloudflare Tunnel HTTPS hostname (and `http://localhost` for dev). Client ID/secret in ENV. Access/refresh tokens stored server-side via Rails encrypted credentials mechanism or an encrypted non-UI secret store — not plain `settings` text fields. Config shows status + Connect/Disconnect only.

**Why:** Personal Google Calendars need user OAuth; service accounts do not fit consumer Gmail calendars without Workspace domain-wide delegation.

**Pi constraint (explicit):** Google's web OAuth redirects require HTTPS (or localhost). LAN-only `http://192.168.x.x` cannot complete Connect unless the operator uses tunnel HTTPS or a one-time localhost/dev flow to obtain a refresh token. Document this as an operational prerequisite, not an in-app login system (app remains single-user / externally gated).

**Alternatives considered:**
- Installed-app / copy-paste refresh token only — simpler ops, weaker Config UX
- Keep iframe — rejected

### 4. Allowlist in Settings; secrets outside Settings
**Choice:** Add a non-secret Settings column (JSON/text array of Google calendar IDs) editable on Config after connect. List available calendars from Google when connected. Tokens/client secrets never rendered.

**Migration:** One additive SQLite migration on `settings`; reversible; no Entry/People touch.

### 5. Server boundary and normalized event value object
**Choice:** Dedicated integration module (fetch → normalize → filter cancelled → expand multi-day onto local dates → dedupe by reliable Google identity → group by date). In-memory value object fields: provider, external event id, calendar id, title, start, end, all_day flag. No DB model for events.

**Day assignment:**
- Timed: convert to `Time.zone`, place on every local date the interval overlaps
- All-day: honor Google date / exclusive end-date convention; do not apply timed TZ shifting

**Fetch window:** Start of current ISO week through end of next ISO week in `Time.zone`, using Google `singleEvents=true` for recurrence expansion.

### 6. Async load via JSON endpoint + Stimulus
**Choice:** Homepage renders grid shell immediately (dates from `Time.zone.today`). Stimulus requests a same-origin JSON endpoint for events. Subtle loading state; populate cells; handle error/reconnect. Abort or ignore stale responses on Turbo morph/leave (request id or AbortController).

**Why:** Matches Hotwire stack; avoids blocking Favorites/Recent Timeline; no Redis job queue.

**Alternatives:** Turbo Frame lazy-load of HTML partial — also fine; prefer JSON if overflow/reveal is client-driven. Either is acceptable if specs hold; default to Stimulus + JSON for clear loading/error states without full section replace flicker.

### 7. New Entry seeding
**Choice:** Extend `EntriesController#new` / `EntryDraft` to accept an optional body seed query param (name chosen to avoid colliding with `entry[body_markdown]` form field), applied only when no overriding session draft exists. Date continues via existing `occurred_on` ISO param. Event links use cell date + URL-encoded title. Preserve validation-failure redisplay.

**Why:** Reuses one creation workflow; no parallel Entry path.

**Security:** Treat title as plain text for the textarea/editor value; rely on existing Markdown sanitize on display; never embed raw title into HTML attribute contexts without escaping; do not log tokens.

### 8. Overflow UX
**Choice:** Show 3 titles + `+N more`. Reveal remaining inline (expand cell or small popover) without leaving homepage. Stable min-height on grid while loading to limit layout jump.

### 9. Client library
**Choice:** Prefer a small OAuth2 + Google Calendar REST client (official google-apis-calendar_v3 / googleauth, or Faraday + token refresh). Avoid large unrelated Google surface area.

### 10. Testing
**Choice:** Minitest unit tests for ISO week range, all-day exclusive end, timed TZ assignment, DST edge, multi-day expansion, dedupe-by-id. Controller/request tests for async endpoint failure modes and New Entry seeding (including special characters). Stub Google HTTP; no live API in CI. Presenter/helper tests for grid dates (mirror homepage_presenter_test style).

## Risks / Trade-offs

- [OAuth HTTPS callback required] → Document Cloudflare Tunnel redirect URI; support localhost for dev; Config Connect fails clearly on misconfigured redirect
- [Token storage on single-user Pi] → Encrypted server-side storage; never expose to browser; Disconnect clears tokens
- [Google API quota / Pi latency] → Per-visit fetch of two weeks only; no polling; graceful timeout; homepage remains usable
- [URL length for long event titles] → Titles are usually short; if pathological, fall back to POST-redirect seed via short-lived session flash/draft seed (implementation detail if GET proves insufficient)
- [Duplicate calendar identities ambiguous] → Deduplicate only on reliable Google identity; never title+date
- [Baseline “calendar import” deferred language] → Specs state display + manual seed ≠ automatic import; no auto-persist
- [Removing iframe] → Operators using only `GOOGLE_CALENDAR_EMBED_URL` must complete OAuth setup; document migration in README

## Migration Plan

1. Ship additive Settings migration and Google integration behind Config (disconnected by default).
2. Replace homepage iframe with grid shell + async fetch.
3. Update README/`.env.example`: add OAuth env vars; mark embed URL obsolete.
4. Register Google Cloud OAuth client; add tunnel HTTPS redirect URI.
5. Operator Connect → select allowlist → verify homepage.
6. Rollback: revert deploy; iframe removal means calendar section needs prior version or stays empty grid until reconnect — no Entry data migration risk. Settings allowlist column can remain unused.

## Open Questions

- Exact ENV vs `Rails.application.credentials` split for client secret vs refresh token can be finalized during apply as long as secrets never render in Config HTML.
- Inline expand vs popover for `+N more` — either satisfies the reveal-without-navigation requirement.
