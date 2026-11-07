# Spec Delta

## MODIFIED Requirements

### Requirement: Optional calendar integration boundary
If Google Calendar integration is configured, it MUST remain read-only unless a future specification explicitly changes this. PRM MUST NOT automatically create, modify, or delete calendar events, or convert calendar events into Entries. Calendar failure MUST NOT prevent core PRM functionality from loading. The homepage MUST present Upcoming Calendar as a native two-week grid section rather than an embedded third-party calendar iframe.

#### Scenario: Calendar unavailable
- **WHEN** calendar credentials are absent or the provider cannot be reached and the homepage loads
- **THEN** the rest of PRM MUST remain functional and calendar functionality SHOULD show a graceful unavailable state

#### Scenario: Native upcoming calendar section
- **WHEN** the homepage loads
- **THEN** Upcoming Calendar MUST render as a native homepage section grid and MUST NOT depend on a Google Calendar iframe embed for its primary presentation

## ADDED Requirements

### Requirement: Non-blocking calendar fetch
Homepage rendering of Favorite People, Recent Timeline, and other non-calendar sections MUST NOT wait for Google Calendar API responses. Upcoming Calendar's grid shell MAY render with the homepage while events populate asynchronously afterward.

#### Scenario: Homepage available during Google latency
- **WHEN** Google Calendar is slow or pending
- **THEN** Favorite People, Recent Timeline, and other non-calendar homepage sections MUST still render without waiting for Google
