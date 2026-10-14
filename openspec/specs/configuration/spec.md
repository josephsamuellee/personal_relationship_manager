## Purpose

Defines the configuration page placement, extensibility for preferences, and operational statistics for database size and Entry counts.

## Requirements

### Requirement: Configuration page
The application MUST provide a configuration page. A link to Configuration MUST exist at the bottom of the homepage such that reaching it normally requires scrolling through homepage content. The configuration system SHOULD be extensible for future application preferences.

#### Scenario: Reach configuration from homepage
- **WHEN** the user scrolls to the bottom of the homepage and selects Configuration
- **THEN** the configuration page MUST open

### Requirement: Database size display
The configuration page MUST display the current database size. The size MUST be expressed in megabytes. The primary display MUST NOT switch units to KB or GB.

#### Scenario: Size shown in megabytes
- **WHEN** the user opens the configuration page
- **THEN** database size MUST be shown in megabytes without switching the primary unit to KB or GB

### Requirement: Entry statistics
The configuration page MUST expose the total number of Entries and the number of Entries created within the previous 30 days. The recent-created statistic MUST use record creation time rather than occurred_on.

#### Scenario: Thirty-day created count uses created_at
- **WHEN** an Entry was created recently but has an older occurred_on date
- **THEN** the previous-30-days created statistic MUST count it based on creation time, not occurred_on
