## Purpose

Defines dated journal Entries, Markdown authority, create and edit workflows with direct Save and person-resolution fallback, transactional persistence, and the canonical Entry detail page.

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
Entry creation MUST use an explicit validation and save workflow conceptually progressing through draft edit, date parse, people parse, tag parse, person resolution when needed, validation, and persist. New Entry MUST present a primary Save control instead of a mandatory Preview control. When Save succeeds with a fully valid draft, the Entry MUST persist in that request without requiring a separate Preview step. When Save encounters unresolved or ambiguous people, the application MUST stage the draft and reuse the existing person-resolution workflow before persistence. The final Entry MUST NOT be persisted merely because a draft was staged for resolution.

#### Scenario: Preview does not persist
- **WHEN** the user reaches the person-resolution or staged-draft step without confirming save
- **THEN** the system MUST NOT persist the final Entry solely because the draft was staged or previewed

#### Scenario: Valid new entry saves directly
- **WHEN** the user opens New Entry, enters a valid title, date, body, and at least one recognized person, and clicks Save
- **THEN** the system MUST validate the Entry, persist it exactly once during that request, redirect to the new Entry detail page, and show a success notice without requiring Preview

#### Scenario: Staged resolution does not persist by itself
- **WHEN** the user reaches the person-resolution workflow because of unresolved people and has not confirmed Save
- **THEN** the system MUST NOT persist the final Entry solely because the draft was staged

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
When editing changes Person associations and the draft is otherwise valid for Save, the system MUST apply relationship additions, removals, and primary-person ordering according to existing association rules on successful Save without requiring a separate relationship-diff confirmation screen. The existing relationship-diff display MAY appear in the person-resolution workflow but MUST NOT block a valid direct Save.

#### Scenario: Preview relationship diff
- **WHEN** an edit changes which People are associated with an Entry
- **THEN** the workflow MAY expose the resulting relationship changes in the person-resolution UI, and a valid direct Save MUST NOT be blocked solely because associations changed

#### Scenario: Add person reference on direct Save
- **WHEN** an existing Entry references one Person and the user adds another recognized Person reference then clicks Save with a valid draft
- **THEN** the Entry MUST be updated and the new Person association MUST be added according to existing rules without a separate confirmation screen

#### Scenario: Remove person reference on direct Save
- **WHEN** an existing Entry references two People and the user removes one recognized reference then clicks Save with a valid draft
- **THEN** the removed association MUST be dropped, the Person record MUST remain, and no separate confirmation screen MUST be required

#### Scenario: Primary person ordering on direct Save
- **WHEN** the user changes wiki-reference ordering among recognized People and clicks Save with a valid draft
- **THEN** existing primary-versus-secondary selection rules MUST apply without requiring relationship-diff confirmation

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

### Requirement: Direct Save on Edit Entry
Edit Entry MUST present a primary Save control instead of a mandatory Preview control. The normal editing interface MUST NOT display a secondary Preview button. Save MUST submit the same Entry form fields used today, including the Markdown body. When the draft is fully valid, Save MUST update the existing Entry exactly once and redirect to that Entry's detail page with an update success notice.

#### Scenario: Valid existing entry updates directly
- **WHEN** the user edits an existing Entry so all validation conditions are satisfied and clicks Save
- **THEN** the existing Entry MUST be updated, no additional Entry MUST be created, and the user MUST be redirected to that Entry's detail page without requiring Preview

#### Scenario: No-op edit preserves Markdown
- **WHEN** the user opens an existing Entry for editing, makes no changes, and clicks Save
- **THEN** the existing Entry MUST remain valid, its Markdown content MUST be preserved, and unnecessary Markdown normalization MUST NOT occur

### Requirement: Person-resolution fallback on Save
When Save encounters unknown or ambiguous person references, the application MUST reuse the existing Preview/person-resolution workflow without introducing inline resolution panels, autocomplete, or automatic Person creation.

#### Scenario: Unknown person
- **WHEN** an Entry contains a wiki reference to a Person that does not exist and the user clicks Save
- **THEN** the system MUST stage the draft without persisting, display the existing person-resolution UI, and allow resolution through existing functionality

#### Scenario: Ambiguous person
- **WHEN** a wiki reference matches multiple existing People and the user clicks Save
- **THEN** the application MUST display the existing ambiguity-resolution controls and MUST NOT persist until the reference is resolved

#### Scenario: Multiple unresolved people
- **WHEN** an Entry references multiple unknown or ambiguous people and the user clicks Save
- **THEN** all references MUST be handled using the existing resolution workflow and the Entry MUST persist only after all required references are resolved

#### Scenario: Resolution completed then Save
- **WHEN** an Entry was staged because of unresolved references and the user completes resolution then confirms Save
- **THEN** the system MUST persist the resolved Entry, clear the staged draft according to existing session conventions, and redirect to the saved Entry

### Requirement: Validation precedence on Save
When unresolved person references and ordinary validation errors both exist, the existing person-resolution UI MUST be shown first. Ordinary validation errors MUST still be preserved and MUST block persistence until both concerns succeed.

#### Scenario: Unknown person and invalid date
- **WHEN** an Entry contains an unknown person reference and an invalid date and the user clicks Save
- **THEN** the application MUST display the existing person-resolution UI, preserve the invalid date and other submitted fields, communicate the date validation error using existing conventions, and prevent persistence until both person resolution and date validation succeed

#### Scenario: Invalid fields without unresolved people
- **WHEN** an Entry contains only recognized people and has an invalid required field and the user clicks Save
- **THEN** the application MUST NOT persist, MUST display the relevant validation errors, and MUST preserve the submitted title, date, Markdown, and other fields, preferring re-render of New/Edit when feasible

#### Scenario: Missing required person
- **WHEN** an Entry contains no valid person reference and the user clicks Save
- **THEN** the application MUST NOT persist and MUST display the existing validation error for the missing required person

### Requirement: Session draft compatibility for resolution
The existing session-based draft workflow MUST remain available for person resolution and for Save after resolution. Successful direct Saves SHOULD avoid unnecessary staging and MUST clear stale staged draft data on success.

#### Scenario: Successful direct Save clears staged draft
- **WHEN** an Entry passes all validation and Save completes
- **THEN** stale staged draft data associated with the operation MUST be cleared and the user MUST be redirected to the Entry detail page

#### Scenario: Failed Save requiring resolution stages draft
- **WHEN** an Entry contains unresolved people and the user clicks Save
- **THEN** the complete draft MUST be staged using existing session conventions and the resolution UI MUST receive all necessary information

### Requirement: Single session draft limitation
This change MUST NOT introduce multi-draft session storage, new draft tables, or draft identifiers solely for concurrent tabs. Concurrent draft workflows across tabs MAY interfere under the current single-session-draft behavior.

#### Scenario: Concurrent tabs share one session draft
- **WHEN** two browser tabs each stage Entry drafts in the same session
- **THEN** the later staged draft MAY overwrite the earlier one according to existing single-session-draft behavior

### Requirement: Duplicate submission protection on Save
Save MUST use best-effort frontend protection against accidental repeated Save actions while a request is in flight. This change MUST NOT introduce server-side idempotency tokens, new database columns, or request-deduplication services.

#### Scenario: Repeated Save click while processing
- **WHEN** the user clicks Save and the request is being processed
- **THEN** the Save control SHOULD become temporarily disabled and SHOULD provide a visible saving state where supported by existing Turbo behavior

### Requirement: Concurrent edit last-write-wins
Concurrent edits of the same Entry MUST preserve existing last-write-wins update semantics. This change MUST NOT introduce optimistic locking, conflict dialogs, or version tracking.

#### Scenario: Concurrent edits
- **WHEN** two browser tabs edit the same Entry and both submit valid changes
- **THEN** existing update semantics MUST apply and the later successful update MAY overwrite earlier changes

### Requirement: Persistence failure reporting
When persistence of a valid draft fails, the application MUST report the failure, MUST NOT present the Entry as successfully saved, and MUST NOT leave partially applied Entry relationships from that attempt.

#### Scenario: Persistence failure
- **WHEN** Save attempts to persist an Entry and persistence fails
- **THEN** the application MUST report the failure, MUST NOT present success, and MUST NOT leave partially applied Entry relationships
