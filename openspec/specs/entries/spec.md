## Purpose

Defines dated journal Entries, Markdown authority, create and edit workflows with preview-before-save, transactional persistence, and the canonical Entry detail page.

## Requirements

### Requirement: Dated Entry
An Entry represents one dated journal or relationship event. An Entry MUST have an explicit title, exactly one occurred_on date, Markdown content, and at least one associated Person.

#### Scenario: Minimal valid Entry
- **WHEN** the user provides a title, an unambiguous date, Markdown body, and at least one resolved Person
- **THEN** the Entry MAY be persisted as a valid dated Entry

### Requirement: One-date invariant
Every Entry MUST correspond to exactly one calendar date. The system MUST NOT represent an Entry using a date range. Distinct multi-day events SHOULD be represented by separate Entries when exact chronological representation is required.

#### Scenario: Multi-day activity
- **WHEN** distinct events occurred on Friday, Saturday, and Sunday and exact chronological representation is required
- **THEN** those events SHOULD be represented by separate Entries

### Requirement: Original Markdown is authoritative
The application MUST store user-authored Markdown. Rendered HTML MUST NOT become the authoritative representation. Rendered Markdown MUST be sanitized before display.

#### Scenario: Display sanitization
- **WHEN** an Entry body is shown on an Entry detail or timeline surface
- **THEN** the displayed HTML MUST be produced from stored Markdown and MUST be sanitized

### Requirement: Explicit creation workflow
Entry creation MUST use an explicit validation and save workflow conceptually progressing through draft edit, date parse, people parse, tag parse, person resolution, preview or validate, explicit save, and persist. The final Entry MUST NOT be persisted merely because the user reached the preview step.

#### Scenario: Preview does not persist
- **WHEN** the user reaches the Entry preview or validation step without confirming save
- **THEN** the system MUST NOT persist the final Entry solely because preview was reached

### Requirement: Explicit title
The user MUST provide an Entry title. The system MUST NOT infer the title automatically from the body.

#### Scenario: Missing title rejected
- **WHEN** the user attempts to save an Entry without a title
- **THEN** validation MUST fail and the Entry MUST NOT be persisted

### Requirement: Transactional persistence on create
Creation of an Entry and its associations MUST behave atomically. A failed validation MUST NOT leave a partially created Entry or partially updated associations.

#### Scenario: Create validation failure
- **WHEN** Entry creation validation fails during persistence
- **THEN** the database MUST NOT contain a partially created Entry or partial associations from that attempt

### Requirement: Existing Entries are editable
A persisted Entry MUST support editing. Editing MUST use substantially the same parsing and validation rules as creation. Changes to date, People, primary Person, Tags, title, and Markdown MUST be reflected after save.

#### Scenario: Edit title and date
- **WHEN** the user edits an Entry's title and occurred_on and saves successfully
- **THEN** subsequent views of that Entry MUST show the updated title and date

### Requirement: Relationship-changing edits
When editing changes Person associations, the system MUST expose the resulting relationship changes before final persistence.

#### Scenario: Preview relationship diff
- **WHEN** an edit changes which People are associated with an Entry
- **THEN** the workflow SHOULD expose the resulting relationship changes before final persistence

### Requirement: Transactional update
Entry updates and association updates MUST occur transactionally. A failed update MUST NOT leave partially updated relationships.

#### Scenario: Association validation fails
- **WHEN** an Entry update changes People and Tags and one required validation fails
- **THEN** the transaction MUST roll back and the database MUST NOT contain a partially updated Entry

### Requirement: Canonical Entry page
Every Entry MUST have an addressable detail page exposing title, occurred date, associated People, primary or secondary relationship where applicable, rendered Markdown, Tags, and an editing control. Search results, timelines, and other Entry references SHOULD link to this canonical Entry.

#### Scenario: Open Entry from search
- **WHEN** the user selects an Entry from search results
- **THEN** the application SHOULD open that Entry's canonical detail page

### Requirement: Single source of truth
Each Entry MUST exist as one authoritative record. Person pages, search results, homepage timelines, and other views MUST reference that same Entry.

#### Scenario: Same Entry across surfaces
- **WHEN** an Entry appears on a Person page and in Recent Timeline
- **THEN** both surfaces MUST refer to the same authoritative Entry record

### Requirement: Testable deterministic parsers
Parsing logic MUST remain separated from presentation and controller logic sufficiently to be independently tested. Conceptual responsibilities include date parsing, wiki person parsing, tag parsing, person resolution, and draft validation. Equivalent implementation names MAY be used.

#### Scenario: Parser unit coverage
- **WHEN** date, wiki person, or tag parsing behavior changes
- **THEN** those behaviors SHOULD be verifiable through tests that do not require full page rendering
