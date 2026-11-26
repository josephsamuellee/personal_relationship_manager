## Purpose

Defines durable unfinished Entry drafts stored in SQLite, kept separate from committed Entries, and addressable for Save and person resolution without cookie-sized session payloads.

## ADDED Requirements

### Requirement: Durable unfinished draft storage
Unfinished Entry drafts MUST be stored as server-side records in the application's SQLite database. Draft records MUST remain distinct from committed Entries. The system MUST NOT rely on browser cookie session payloads to hold Markdown body or other draft field content.

#### Scenario: Long draft does not use cookie payload
- **WHEN** an unfinished draft contains a Markdown body of approximately 4 KB or larger and is staged for person resolution
- **THEN** the draft content MUST be stored server-side and the session cookie MUST NOT contain the full draft payload

#### Scenario: Draft survives process restart
- **WHEN** an unfinished draft exists in the database and the application process restarts
- **THEN** that draft MUST still be loadable for resume, Preview, or Save

### Requirement: Draft field retention
A persistent draft MUST retain title, raw date input, Markdown body, optional association to an existing Entry, and person-resolution selections. Incomplete or invalid field values MUST be allowed on the draft record. Parsed people, tags, resolved ids, and validation errors MUST be re-derived when the draft is loaded or validated rather than treated as the sole authoritative stored form.

#### Scenario: Incomplete draft retained
- **WHEN** the user stages a draft with a blank title or unparseable date during a Save that requires person resolution
- **THEN** those submitted field values MUST remain available on the persistent draft for subsequent editing or Preview

### Requirement: Isolation from committed Entry surfaces
Unfinished drafts MUST NOT appear as committed Entries in homepage timeline, Person history, relationship statistics, tag results, Entry search, or other committed Entry queries.

#### Scenario: Search ignores unfinished drafts
- **WHEN** an unfinished draft exists whose title or body would match an Entry search query
- **THEN** search results MUST NOT list that draft as a committed Entry

### Requirement: No automatic Person or relationship side effects on draft persistence
Persisting or updating an unfinished draft MUST NOT create Person records, committed Entry-Person relationships, or Entry tags by itself. Explicit person-resolution actions that already create People MAY continue to do so when the user invokes them.

#### Scenario: Draft upsert does not create People
- **WHEN** a draft containing `[[Unknown Person]]` is written to durable storage without an explicit create-person action
- **THEN** no Person named Unknown Person MUST be created solely because the draft was stored

### Requirement: Draft identity for resolution workflow
Person-resolution and Preview flows for an unfinished Entry MUST operate against a specific durable draft identity. Resolution actions MUST update that draft's retained fields and selections. Successful committed Save of that draft MUST remove only that draft record.

#### Scenario: Resolution updates the same draft
- **WHEN** the user resolves an ambiguous person reference for a staged draft
- **THEN** the updated selections MUST be stored on that same durable draft and subsequent Preview MUST reflect them

#### Scenario: Successful Save removes the draft
- **WHEN** the user successfully persists the Entry from a durable draft
- **THEN** that draft record MUST be removed and MUST NOT remain listed as unfinished
