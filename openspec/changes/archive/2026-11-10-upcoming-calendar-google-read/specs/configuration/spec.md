# Spec Delta

## ADDED Requirements

### Requirement: Google Calendar connection status
The configuration page MUST show whether Google Calendar is disconnected, connected, or requires reconnect. Operators MUST be able to start connection and disconnect from Config. OAuth client secrets and access or refresh tokens MUST NOT appear as ordinary editable configuration fields and MUST NOT be rendered into the page.

#### Scenario: Disconnected state
- **WHEN** Google Calendar is not authorized
- **THEN** Config MUST show a disconnected state and a control to begin connection

#### Scenario: Reconnect required
- **WHEN** stored authorization can no longer be used and reauthorization is required
- **THEN** Config MUST show a reconnect-required state without displaying token values

#### Scenario: Disconnect
- **WHEN** the operator disconnects Google Calendar from Config
- **THEN** subsequent Upcoming Calendar fetches MUST NOT use the prior authorization

### Requirement: Calendar allowlist selection
When Google Calendar is connected, Config MUST let the operator select which calendars are included in Upcoming Calendar using an allowlist of one or more calendars. Saving the allowlist MUST affect subsequent homepage event fetches. The allowlist MAY be empty.

#### Scenario: Save allowlist
- **WHEN** the operator selects calendars A and C and saves
- **THEN** subsequent Upcoming Calendar loads MUST use A and C as the allowlist

#### Scenario: Clear allowlist
- **WHEN** the operator clears all calendar selections and saves
- **THEN** Upcoming Calendar MUST treat the allowlist as empty until calendars are selected again
