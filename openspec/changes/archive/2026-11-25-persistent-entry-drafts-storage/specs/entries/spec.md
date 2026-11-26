## MODIFIED Requirements

### Requirement: Explicit creation workflow
Entry creation MUST use an explicit validation and save workflow conceptually progressing through draft edit, date parse, people parse, tag parse, person resolution when needed, validation, and persist. New Entry MUST present a primary Save control instead of a mandatory Preview control. When Save succeeds with a fully valid draft, the Entry MUST persist in that request without requiring a separate Preview step. When Save encounters unresolved or ambiguous people, the application MUST stage a durable server-side draft and reuse the existing person-resolution workflow before persistence. The final Entry MUST NOT be persisted merely because a draft was staged for resolution.

#### Scenario: Preview does not persist
- **WHEN** the user reaches the person-resolution or staged-draft step without confirming save
- **THEN** the system MUST NOT persist the final Entry solely because the draft was staged or previewed

#### Scenario: Valid new entry saves directly
- **WHEN** the user opens New Entry, enters a valid title, date, body, and at least one recognized person, and clicks Save
- **THEN** the system MUST validate the Entry, persist it exactly once during that request, redirect to the new Entry detail page, and show a success notice without requiring Preview

#### Scenario: Staged resolution does not persist by itself
- **WHEN** the user reaches the person-resolution workflow because of unresolved people and has not confirmed Save
- **THEN** the system MUST NOT persist the final Entry solely because the draft was staged

### Requirement: Person-resolution fallback on Save
When Save encounters unknown or ambiguous person references, the application MUST reuse the existing Preview/person-resolution workflow without introducing inline resolution panels, autocomplete, or automatic Person creation. Staging MUST use durable server-side draft storage rather than embedding the full draft in a browser cookie session.

#### Scenario: Unknown person
- **WHEN** an Entry contains a wiki reference to a Person that does not exist and the user clicks Save
- **THEN** the system MUST stage a durable draft without persisting the Entry, display the existing person-resolution UI, and allow resolution through existing functionality

#### Scenario: Ambiguous person
- **WHEN** a wiki reference matches multiple existing People and the user clicks Save
- **THEN** the application MUST display the existing ambiguity-resolution controls and MUST NOT persist until the reference is resolved

#### Scenario: Multiple unresolved people
- **WHEN** an Entry references multiple unknown or ambiguous people and the user clicks Save
- **THEN** all references MUST be handled using the existing resolution workflow and the Entry MUST persist only after all required references are resolved

#### Scenario: Resolution completed then Save
- **WHEN** an Entry was staged because of unresolved references and the user completes resolution then confirms Save
- **THEN** the system MUST persist the resolved Entry, remove the corresponding durable unfinished draft, and redirect to the saved Entry

#### Scenario: Long body requiring resolution
- **WHEN** the user clicks Save on a draft whose Markdown body is approximately 4 KB or larger and at least one person reference is unresolved
- **THEN** the application MUST stage the durable draft and show the resolution UI without failing due to browser cookie capacity limits

### Requirement: Session draft compatibility for resolution
The durable unfinished-draft workflow MUST remain available for person resolution and for Save after resolution. Successful direct Saves SHOULD avoid unnecessary staging when no draft row is required and MUST remove the corresponding durable draft on success. The requirement name remains for baseline continuity; behavior refers to server-side drafts rather than cookie session payloads.

#### Scenario: Successful direct Save clears staged draft
- **WHEN** an Entry passes all validation and Save completes
- **THEN** the corresponding durable draft MUST be removed when one exists and the user MUST be redirected to the Entry detail page

#### Scenario: Failed Save requiring resolution stages draft
- **WHEN** an Entry contains unresolved people and the user clicks Save
- **THEN** the complete submitted draft MUST be stored as a durable server-side draft and the resolution UI MUST receive all necessary information via that draft identity

## REMOVED Requirements

### Requirement: Single session draft limitation
**Reason:** Unfinished drafts move to server-side SQLite records. Multi-draft UX is owned by a later dependent change; this foundation must not forbid draft tables or draft identifiers.

## ADDED Requirements

### Requirement: Draft cleanup with Entry persistence
When a valid draft is persisted as a committed Entry, removal of the corresponding unfinished draft MUST occur in the same transactional boundary as Entry persistence where feasible so a successful Save does not leave a stale unfinished draft for that work.

#### Scenario: Atomic success path
- **WHEN** Save persists a new or updated Entry from a durable draft successfully
- **THEN** that unfinished draft MUST NOT remain queryable as unfinished after the transaction commits
