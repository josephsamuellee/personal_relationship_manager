# Personal Relationship Manager

A lightweight, private, single-user relationship knowledge server built with Rails 7.2 and SQLite.

## Features

- Journal entries with `[[Person]]` wiki links and `#tags`
- Person pages with proportional timeline, about section, and recent entries
- Homepage with recent timeline, calendar embed, historical lookback, and random reminders
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
| `GOOGLE_CALENDAR_EMBED_URL` | Google Calendar iframe embed URL |
| `SECRET_KEY_BASE` | Required in production |

Never commit secrets. Do not expose the service publicly without access controls (e.g. Cloudflare Tunnel with authentication).

## Raspberry Pi Deployment

1. Install Ruby 3.3 and dependencies on ARM64
2. Clone the repo and run `bundle install --without development test`
3. Set environment variables (see `.env.example`)
4. Run `RAILS_ENV=production bin/rails db:prepare assets:precompile`
5. Start with Puma: `RAILS_ENV=production bin/rails server -b 0.0.0.0 -p 3000`

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
ExecStart=/home/pi/.rbenv/shims/bundle exec rails server -b 0.0.0.0 -p 3000
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

## Docker (ARM64)

```bash
cp .env.example .env
# Edit .env with SECRET_KEY_BASE and optional GOOGLE_CALENDAR_EMBED_URL

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
