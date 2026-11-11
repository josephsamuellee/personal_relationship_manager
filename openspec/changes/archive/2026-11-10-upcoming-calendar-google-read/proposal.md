# Proposal

## Why

The homepage already labels a section "Upcoming Calendar," but it is only a Google Calendar iframe. That answers "what is scheduled?" in Google's UI, not PRM's prospective relationship question: who am I about to interact with, and what can I turn into an Entry afterward? Recent Timeline covers the retrospective side; Upcoming Calendar should supply the missing forward-looking surface without inventing a second calendar database inside PRM.

## What Changes

- Replace the homepage Google Calendar iframe with a native two-ISO-week Upcoming Calendar grid (current week + next week, Monday–Sunday).
- Add read-only Google Calendar API integration with minimum OAuth scopes, a Config-page connection status + calendar allowlist, and fresh per-visit event fetches for the displayed range.
- Load the calendar grid with the homepage; fetch and populate Google events asynchronously without blocking Favorites, Recent Timeline, or other sections.
- Clicking a day opens existing New Entry with that `occurred_on`; clicking an event opens New Entry with that cell's date and the event title as the Markdown body (no auto-persist, no person matching).
- Use `APP_TIME_ZONE` / Rails `Time.zone` as the sole display timezone for today, ISO weeks, and timed-event day assignment.
- Document Pi/Cloudflare Tunnel OAuth callback and secret externalization; remove reliance on `GOOGLE_CALENDAR_EMBED_URL`.
- **Out of scope:** calendar write/RSVP, person matching, auto Entry/draft/TODO/follow-up creation, background sync, event persistence tables, agenda/hourly views, more than two weeks, editable PRM calendar events. Manual New Entry initialization from a clicked event is not automatic Google→Entry import.

## Capabilities

### New Capabilities
- `upcoming-calendar`: Homepage prospective calendar grid, read-only Google event display (including recurrence/multi-day/overflow), async load/error states, and click-through initialization of New Entry from dates/events.

### Modified Capabilities
- `homepage`: Replace the iframe-oriented optional calendar boundary with the native Upcoming Calendar section and keep calendar failure isolated from core homepage load.
- `configuration`: Add Google Calendar connection status and multi-calendar allowlist controls on the Config page without exposing secrets as ordinary editable fields.
- `entries`: Allow New Entry to initialize `occurred_on` (already) and Markdown body from safe request parameters when arriving from Upcoming Calendar, without changing Save/validation semantics.
- `deployment`: Externalize Google OAuth client credentials and tokens; document HTTPS callback expectations for Cloudflare Tunnel; retire embed-URL calendar configuration.

## Impact

- **UI:** `app/views/homepage/show.html.erb`, new calendar partials/CSS, Stimulus controller for async fetch + overflow reveal; Config page Google section.
- **Server:** Replace/extend `CalendarProvider` / `EmbedCalendarProvider` with API fetch + normalize + group-by-date services; new JSON endpoint for the two-week window; OAuth connect/callback/disconnect routes; Settings column(s) for allowlist (non-secret).
- **Entries:** `EntriesController#new` / `EntryDraft` accept optional body seed from params; reuse existing `occurred_on` ISO date param.
- **Deps:** Google Calendar API client (or thin HTTP + OAuth2); no Redis/Sidekiq/Postgres; no Entry schema change for external events.
- **Ops:** Requires Google Cloud OAuth client, HTTPS redirect URI (tunnel hostname), and ENV/credentials for secrets. Homepage remains usable when Google is disconnected or failing.
- **Baseline tension:** Project context defers "calendar write/import"; this change is read-only display plus manual Entry form seeding, not automatic import or write-back.
