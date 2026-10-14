## Purpose

Defines Person identity, naming, dedicated Person pages, about Markdown, chronological person timelines, and recent Entry listings.

## Requirements

### Requirement: Person identity
A Person MUST have a stable database identity. A Person SHOULD contain at least id, name, slug, about_markdown, created_at, and updated_at. The database ID MUST remain the authoritative identity. A slug MUST NOT replace the database ID as the underlying identity.

#### Scenario: Stable identity across rename
- **WHEN** a Person's display name changes but the database ID is unchanged
- **THEN** existing Entry associations MUST continue to refer to that same Person

### Requirement: Person names
A Person MUST have a name. Additional information such as email, phone number, employer, or birthday MUST NOT be required merely to create a Person.

#### Scenario: Minimal Person creation
- **WHEN** the user creates a Person with only a name
- **THEN** the system MUST persist the Person without requiring contact or biographical fields

### Requirement: Person detail page
Every Person MUST have a dedicated page. The page SHOULD contain Person name, chronological timeline, About information, recent Entries, favorite-position configuration, and future-compatible space for additional relationship information.

#### Scenario: Navigate to Person page
- **WHEN** the user opens a Person from See All People or another Person link
- **THEN** the dedicated Person page MUST display that Person's name and associated content areas

### Requirement: Person timeline chronology
The Person timeline MUST represent actual elapsed calendar time. Events MUST NOT simply be evenly spaced according to event count. The leftmost point represents the oldest associated Entry. The right boundary represents today. Every Entry associated with the Person SHOULD be represented.

#### Scenario: Uneven event spacing
- **WHEN** a Person has Entries clustered in one month and another Entry years later
- **THEN** the timeline MUST preserve chronological spacing rather than equal spacing by event count

### Requirement: Timeline collisions
Entries occurring close together MUST preserve their horizontal chronological position. When visual nodes collide, the interface SHOULD vertically stack or stagger them rather than changing their dates or aggregating unrelated Entries.

#### Scenario: Same-day Entries
- **WHEN** two Entries for the same Person share the same occurred_on date
- **THEN** both MUST remain distinct on the timeline without merging into one aggregated event

### Requirement: Primary versus secondary Entries on timeline
The Person timeline MUST distinguish Entries for which the Person is primary from Entries for which the Person is secondary or shared.

#### Scenario: Shared Entry appearance
- **WHEN** a Person is secondary on an Entry that also appears on their timeline
- **THEN** the timeline SHOULD visually distinguish that Entry from primary Entries

### Requirement: Timeline interaction
Selecting a Person timeline Entry MUST allow its contents to be viewed without unnecessarily losing the Person-page context. A modal, overlay, or equivalent interaction MAY be used.

#### Scenario: View Entry from timeline
- **WHEN** the user selects an Entry node on the Person timeline
- **THEN** the Entry contents SHOULD be viewable without requiring a full navigation away that loses Person-page context

### Requirement: About Markdown
A Person MUST support relatively timeless Markdown reference information. The user MUST be able to edit and save this information. Person wiki links appearing in About Markdown MAY render as Person links. Such links MUST NOT create Entry-Person associations.

#### Scenario: About wiki link does not associate Entry
- **WHEN** About Markdown contains a Person wiki link and is saved
- **THEN** the link MAY render as a Person link and MUST NOT create an Entry-Person association

### Requirement: Recent Entries on Person page
The Person page SHOULD display the five most recent Entries involving that Person. Ordering MUST primarily use occurred_on descending.

#### Scenario: Recent Entries order
- **WHEN** a Person has more than five associated Entries
- **THEN** the recent list SHOULD show the five with the latest occurred_on values first
