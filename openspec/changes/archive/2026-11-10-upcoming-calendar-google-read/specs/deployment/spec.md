# Spec Delta

## ADDED Requirements

### Requirement: Google OAuth callback hostname
Google OAuth authorization for Upcoming Calendar MUST use a redirect URI the Google client allows. Production documentation MUST state that a stable HTTPS public hostname such as the Cloudflare Tunnel URL is the expected callback host for non-localhost use, and that plain LAN HTTP hosts are not sufficient for Google's web OAuth redirect rules except where Google explicitly allows localhost during development.

#### Scenario: Document HTTPS callback expectation
- **WHEN** an operator configures Google Calendar connection for Pi production behind Cloudflare Tunnel
- **THEN** deployment documentation MUST identify the HTTPS tunnel hostname as the OAuth redirect host to register with Google

## MODIFIED Requirements

### Requirement: Configuration and secrets externalization
Deployment-specific values SHOULD be externalized, including APP_TIME_ZONE, DATABASE_PATH, Google OAuth client credentials, Google OAuth tokens, calendar-related secrets, and Rails secrets. Secrets MUST NOT be committed to source control. Secrets MUST NOT be stored as ordinary user-editable PRM configuration values. The Google Calendar iframe embed URL MUST NOT be required for Upcoming Calendar.

#### Scenario: Secret not in PRM config UI
- **WHEN** an operator manages SECRET_KEY_BASE or calendar credentials
- **THEN** those values MUST NOT be stored as ordinary user-editable PRM configuration fields in the app UI

#### Scenario: OAuth secrets externalized
- **WHEN** Google Calendar read integration is enabled in production
- **THEN** OAuth client credentials and tokens MUST be supplied through externalized secret storage rather than committed source files or plain Config text fields

#### Scenario: Embed URL not required
- **WHEN** Upcoming Calendar is configured for API-based read access
- **THEN** deployment MUST NOT require `GOOGLE_CALENDAR_EMBED_URL` for the native Upcoming Calendar to function

### Requirement: Application time zone
Features depending on today MUST use the configured application time zone. This includes Recent Timeline, Upcoming Calendar ISO weeks and event-to-day assignment, current ISO week, three-month historical calculation, and 30-day operational statistics where calendar boundaries matter. The expected deployment time zone is America/Los_Angeles unless deployment configuration explicitly overrides it.

#### Scenario: Today uses configured zone
- **WHEN** APP_TIME_ZONE is America/Los_Angeles and local clock crosses midnight in that zone
- **THEN** Recent Timeline's today MUST follow that configured zone rather than an unrelated host-local zone

#### Scenario: Upcoming Calendar uses configured zone
- **WHEN** APP_TIME_ZONE is America/Los_Angeles and the local clock crosses midnight in that zone
- **THEN** Upcoming Calendar's today and day assignment MUST follow that configured zone rather than the browser zone
