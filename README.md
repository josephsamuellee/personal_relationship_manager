# Personal Relationship Manager

A lightweight, private, single-user relationship knowledge server built with Rails 7.2 and SQLite.

## Features

- Journal entries with `[[Person]]` wiki links and `#tags`
- Person pages with proportional timeline, about section, and recent entries
- Homepage with recent timeline, Upcoming Calendar (read-only Google Calendar), historical lookback, and random reminders
- Deterministic search across people, dates, and entries
- Preview-before-save entry workflow with person resolution

## Requirements

- Ruby 3.1+ (3.3 recommended)
- SQLite 3
- Bundler

## Setup

```bash
bundle install
bin/rails db:prepare
bin/rails db:seed   # optional demo data
bin/rails server
```

Visit `http://localhost:3000/homepage`

## Configuration

Copy `.env.example` to `.env` and set:

| Variable | Description |
|----------|-------------|
| `APP_TIME_ZONE` | Application timezone (default: `America/Los_Angeles`) |
| `DATABASE_PATH` | SQLite file path for persistence |
| `SECRET_KEY_BASE` | Required in production |
| `GOOGLE_OAUTH_CLIENT_ID` | Google OAuth Web client ID (Upcoming Calendar) |
| `GOOGLE_OAUTH_CLIENT_SECRET` | Google OAuth Web client secret |
| `GOOGLE_CALENDAR_TOKEN_PATH` | Optional path for encrypted OAuth tokens (default: `storage/google_calendar_tokens.json.enc`) |

`GOOGLE_CALENDAR_EMBED_URL` is obsolete and is no longer used by Upcoming Calendar.

Never commit secrets. Do not expose the service publicly without access controls (e.g. Cloudflare Tunnel with authentication).

### Google Calendar (Upcoming Calendar)

Upcoming Calendar is a native homepage grid (current ISO week + next week). It reads Google Calendar events asynchronously and never writes back to Google.

1. In [Google Cloud Console](https://console.cloud.google.com/), create an OAuth **Web application** client.
2. Add authorized redirect URIs:
   - Production: `https://<your-cloudflare-tunnel-host>/google_calendar/oauth/callback`
   - Development: `http://localhost:3000/google_calendar/oauth/callback`
3. Set `GOOGLE_OAUTH_CLIENT_ID` and `GOOGLE_OAUTH_CLIENT_SECRET` in the environment.
4. Optional: set `GOOGLE_CALENDAR_TOKEN_PATH` (default `storage/google_calendar_tokens.json.enc`). Tokens are encrypted at rest with `SECRET_KEY_BASE` and are never shown in Config HTML.
5. Open **Config → Google Calendar → Connect**, complete Google consent (read-only calendar scope), then select an allowlist of calendars and save.

Google's web OAuth redirect rules require HTTPS (or localhost). A plain LAN `http://192.168.x.x` host is not sufficient for Connect; use the Cloudflare Tunnel HTTPS hostname in production.

Scopes requested: `https://www.googleapis.com/auth/calendar.readonly` (calendar list + events read only).

## Raspberry Pi Deployment

1. Install Ruby 3.3 and dependencies on ARM64
2. Clone the repo and run `bundle install --without development test`
3. Set environment variables (see `.env.example`)
4. Run `RAILS_ENV=production bin/rails db:prepare assets:precompile`
5. Start with `RAILS_ENV=production bin/start -b 0.0.0.0 -p 3000` (runs migrations automatically on boot)

Puma is configured for low resource use (3 threads). SQLite database should live on persistent storage via `DATABASE_PATH`.

The app uses relative URLs and works from both LAN IP (`http://192.168.x.x:3000`) and tunneled hostnames.

### systemd example

```ini
[Unit]
Description=Personal Relationship Manager
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/personal_relationship_manager
Environment=RAILS_ENV=production
Environment=SECRET_KEY_BASE=your-secret
Environment=DATABASE_PATH=/home/pi/prm-data/production.sqlite3
Environment=APP_TIME_ZONE=America/Los_Angeles
ExecStart=/home/pi/personal_relationship_manager/bin/start -b 0.0.0.0 -p 3000
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

## Docker (ARM64)

```bash
cp .env.example .env
# Edit .env with SECRET_KEY_BASE and optional Google OAuth client credentials

docker compose up --build
```

The SQLite database is stored in the `prm_data` Docker volume.

## Testing

```bash
bin/rails test
```

## Security Notes

- No built-in authentication; rely on network/tunnel access controls
- Markdown HTML is sanitized on render
- CSRF protection enabled on all forms
