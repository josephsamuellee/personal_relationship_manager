## MODIFIED Requirements

### Requirement: Explicit creation workflow
Entry creation MUST use an explicit validation and save workflow conceptually progressing through draft edit, date parse, people parse, tag parse, person resolution when needed, validation, and persist. New Entry MUST present a primary Save control instead of a mandatory Preview control. When Save succeeds with a fully valid draft, the Entry MUST persist in that request without requiring a separate Preview step. When Save encounters unresolved or ambiguous people, the application MUST stage a durable server-side draft and reuse the existing person-resolution workflow before persistence. The final Entry MUST NOT be persisted merely because a draft was staged for resolution. Autosave of unfinished drafts MUST NOT replace explicit Save and MUST NOT persist the final Entry by itself.

#### Scenario: Preview does not persist
- **WHEN** the user reaches the person-resolution or staged-draft step without confirming save
- **THEN** the system MUST NOT persist the final Entry solely because the draft was staged or previewed

#### Scenario: Valid new entry saves directly
- **WHEN** the user opens New Entry, enters a valid title, date, body, and at least one recognized person, and clicks Save
- **THEN** the system MUST validate the Entry, persist it exactly once during that request, redirect to the new Entry detail page, and show a success notice without requiring Preview

#### Scenario: Staged resolution does not persist by itself
- **WHEN** the user reaches the person-resolution workflow because of unresolved people and has not confirmed Save
- **THEN** the system MUST NOT persist the final Entry solely because the draft was staged

#### Scenario: Autosave does not publish
- **WHEN** autosave writes an unfinished draft that would be valid for Save
- **THEN** the system MUST NOT create the committed Entry until the user explicitly Saves

## ADDED Requirements

### Requirement: Explicit Save includes latest editor content
Explicit Save MUST submit the current editor field values, including meaningful changes not yet acknowledged by autosave. The client SHOULD flush or include pending edits so Save is not limited to the last autosaved snapshot.

#### Scenario: Save before debounce completes
- **WHEN** the user edits the body and clicks Save before the 3 second autosave debounce completes
- **THEN** the Save request MUST include the latest editor body and MUST apply normal validation, resolution, or persistence rules to that content
