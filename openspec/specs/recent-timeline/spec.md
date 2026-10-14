## Purpose

Defines the homepage Recent Timeline feature identity, inclusive two-week date range, blank-date rows, ISO week indicators, and today emphasis.

## Requirements

### Requirement: Feature identity
The homepage recent-history component MUST use the conceptual or internal name recent_timeline. It MUST NOT be defined merely as a generic 14_days feature.

#### Scenario: Named recent timeline
- **WHEN** the homepage recent-history component is referenced in implementation or configuration
- **THEN** it MUST be identified as recent_timeline rather than only as a generic 14-day feature

### Requirement: Inclusive two-week date range
The timeline MUST include today and the matching weekday two weeks earlier. The normal inclusive range therefore contains 15 calendar dates.

#### Scenario: Sunday range
- **WHEN** today is Sunday and the timeline is generated
- **THEN** it MUST include today and MUST include the Sunday two weeks earlier

### Requirement: Chronological rows by occurred_on
The Recent Timeline MUST contain one row per calendar date. Blank dates MUST remain visible. Entries MUST be grouped using occurred_on. created_at MUST NOT determine timeline placement.

#### Scenario: Blank date remains visible
- **WHEN** a date in the inclusive range has no Entries
- **THEN** that date's row MUST still appear on the timeline

### Requirement: Timeline columns
The timeline MUST support the three-column presentation Week indicator | Weekday | Entries. The weekday column MUST retain the existing one-letter weekday representation. Entry titles MUST link to their Entries. Multiple Entries for one date MAY appear in the same row.

#### Scenario: Entry title links
- **WHEN** a date row contains one or more Entries
- **THEN** each Entry title MUST link to its Entry and MAY share the same row with other Entries for that date

### Requirement: ISO week indicators
Mondays MUST display their ISO 8601 week number using W## form such as W33. ISO week numbering MUST follow ISO 8601, including that W01 is the week containing the year's first Thursday.

#### Scenario: Monday week label
- **WHEN** a Monday appears in the Recent Timeline
- **THEN** that row MUST display the corresponding ISO week number in W## form

### Requirement: Today indicator
Today's row MUST be visually emphasized and MUST be bold. Today's row MUST display the current ISO week number even when today is not Monday. Consequently, many displayed weeks will contain two visible instances of the week number on Monday and today when today is not Monday.

#### Scenario: Today shows week number midweek
- **WHEN** today is Wednesday
- **THEN** today's row MUST be emphasized and MUST display the current ISO week number in addition to Monday's week label
