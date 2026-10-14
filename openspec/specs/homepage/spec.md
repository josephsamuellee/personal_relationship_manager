## Purpose

Defines the primary homepage route and current homepage sections beyond favorites and recent timeline, including optional calendar, historical window, random reminders, and deferred TODO placeholder.

## Requirements

### Requirement: Homepage route
The application MUST provide a primary homepage. The canonical route SHOULD remain `/homepage`.

#### Scenario: Open homepage
- **WHEN** the user navigates to the primary homepage route
- **THEN** the homepage MUST load with its current sections

### Requirement: Optional calendar integration boundary
If Google Calendar integration is configured, it MUST remain read-only unless a future specification explicitly changes this. PRM MUST NOT automatically create, modify, or delete calendar events, or convert calendar events into Entries. Calendar failure MUST NOT prevent core PRM functionality from loading.

#### Scenario: Calendar unavailable
- **WHEN** calendar credentials are absent or the provider cannot be reached and the homepage loads
- **THEN** the rest of PRM MUST remain functional and calendar functionality SHOULD show a graceful unavailable state

### Requirement: Three-month historical window
Where the historical mini-timeline remains present, its anchor MUST use calendar-month arithmetic: anchor equals today minus three calendar months, start equals anchor minus seven days, and end equals anchor plus seven days. The system MUST NOT substitute a fixed 90-days-ago calculation. Entries MUST be selected by occurred_on.

#### Scenario: Calendar-month historical anchor
- **WHEN** the historical mini-timeline is shown
- **THEN** its window MUST be derived from today minus three calendar months plus or minus seven days rather than a fixed ninety-day offset

### Requirement: Random reminders
Where the random or reminder section remains present, random People and random Entries MUST link to their canonical pages. Photo integration remains outside current core requirements.

#### Scenario: Random Entry links to Entry page
- **WHEN** a random Entry appears in the random reminders section
- **THEN** it MUST link to that Entry's canonical page

### Requirement: TODO placeholder
Where the TODO homepage section remains present, it MUST be allowed to show a placeholder indicating reminder and TODO features are deferred. Sophisticated TODO or reminder semantics remain outside current core requirements.

#### Scenario: TODO placeholder does not block homepage
- **WHEN** the homepage TODO section is present as a placeholder
- **THEN** the remainder of the homepage MUST still load and function
