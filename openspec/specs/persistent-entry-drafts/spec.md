# persistent-entry-drafts Specification

## Purpose

Defines durable unfinished Entry drafts stored in SQLite, kept separate from committed Entries, and addressable for Save and person resolution without cookie-sized session payloads.

## Requirements

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

### Requirement: Autosave after idle debounce
While the user edits an Entry draft on New or Edit, the application MUST automatically persist meaningful field changes to the durable unfinished draft after 3 seconds idle following the last meaningful modification. Autosave MUST NOT run on a fixed interval solely because typing continues without pause. Unchanged content relative to the last server-acknowledged snapshot MUST NOT produce unnecessary writes.

#### Scenario: First pause creates or updates draft
- **WHEN** the user changes the Markdown body and then stops editing for 3 seconds
- **THEN** the application MUST send an autosave that creates or updates the durable draft with that content

#### Scenario: Continuous typing without pause
- **WHEN** the user types continuously without a 3 second idle gap
- **THEN** the application MUST NOT rely on a maximum-wait checkpoint to autosave during that uninterrupted typing

#### Scenario: No write when unchanged
- **WHEN** an autosave would fire but editor fields match the last acknowledged server snapshot
- **THEN** the application MUST NOT perform an unnecessary draft write

### Requirement: No draft on open without edits
Opening New Entry or Edit Entry MUST NOT create a durable unfinished draft until the user makes a meaningful modification to title, raw date, or Markdown body.

#### Scenario: Open New Entry and leave
- **WHEN** the user opens New Entry and navigates away without changing fields
- **THEN** no new unfinished draft record MUST be created

#### Scenario: Open Edit Entry and leave
- **WHEN** the user opens Edit Entry for a committed Entry that has no unfinished draft and navigates away without changes
- **THEN** no unfinished draft MUST be created for that Entry

### Requirement: New Entry URL after first autosave
After the first successful autosave that creates a New Entry draft, the browser URL MUST be replaced with that draft's editor address so refresh resumes the same draft. Opening `/entries/new` (or equivalent New Entry entry point) MUST still start a fresh Entry workflow without loading an existing draft.

#### Scenario: Refresh resumes created draft
- **WHEN** the first autosave creates a New draft and the URL has been replaced to the draft editor
- **THEN** refreshing that URL MUST reload the same durable draft content

#### Scenario: Add Entry stays fresh
- **WHEN** the user opens the standard New Entry entry point after other unfinished drafts exist
- **THEN** the editor MUST start blank for a new workflow and MUST NOT auto-load another draft

### Requirement: Autosave never commits Entries
Autosave MUST NOT create or update committed Entries, MUST NOT create Person records, and MUST NOT modify committed Entry-Person relationships or Entry tags. Incomplete and unresolved drafts MUST be autosaveable.

#### Scenario: Unresolved wiki links autosaved
- **WHEN** the body contains `[[Unknown Person]]` and autosave runs
- **THEN** the durable draft MUST store the body and MUST NOT create a Person or Entry

### Requirement: Visible autosave statuses
The Entry editor MUST expose an accurate status reflecting at least: unsaved changes, saving draft, draft saved (after server acknowledgment of the relevant content), and not saved — retrying after failure. A saved indicator MUST require successful server acknowledgment of the content revision being reported.

#### Scenario: Acknowledgment required for saved
- **WHEN** an autosave request has been sent but not yet acknowledged
- **THEN** the UI MUST NOT claim the draft is saved for that unacknowledged content

### Requirement: Automatic retry with bounded backoff
When autosave fails due to transient network or server errors, the editor MUST keep local content, show retrying status, and retry automatically with bounded backoff without retry storms, always sending the newest payload rather than older queued bodies.

#### Scenario: Connectivity returns
- **WHEN** autosave fails while offline and connectivity returns
- **THEN** a later retry MUST persist the latest local editor content to the durable draft

### Requirement: Navigation protection for unacknowledged edits
When the editor has unsaved or unacknowledged meaningful changes, the application MUST provide minimum protection against accidental loss on Turbo navigation and browser unload via confirmation and/or best-effort flush before leave. The system MUST NOT introduce browser-local persistent storage of journal Markdown in this change.

#### Scenario: Turbo leave while dirty
- **WHEN** the user attempts Turbo navigation away with unacknowledged edits
- **THEN** the application MUST prompt or attempt to flush autosave before abandoning those edits without notice

#### Scenario: Debounce window loss on hard kill
- **WHEN** the browser is killed after a meaningful edit but before the debounce fires and before any request reaches the server
- **THEN** those edits MAY be unrecoverable and MUST NOT be assumed preserved by local persistent browser storage

### Requirement: Multiple New Entry drafts
The system MUST allow multiple independent unfinished drafts that are not associated with an existing Entry. Each such draft MUST remain separately resumable until successfully committed or explicitly discarded.

#### Scenario: Two New drafts coexist
- **WHEN** the user creates unfinished content for two separate New Entry workflows via autosave
- **THEN** both durable drafts MUST remain available and discarding one MUST NOT remove the other

### Requirement: Single edit draft per Entry
For a given committed Entry, the system MUST maintain at most one unfinished edit draft. Opening Edit Entry MUST automatically resume that draft when it exists. Opening Edit MUST NOT create a draft until a meaningful modification occurs when no draft exists.

#### Scenario: Edit resumes existing draft
- **WHEN** an unfinished draft exists for Entry E and the user opens Edit for E
- **THEN** the editor MUST load that draft's retained fields rather than silently ignoring them

### Requirement: MRU ordering by meaningful modification
The most recent unfinished draft MUST be determined by last meaningful modification time. Opening, reading, listing, or Previewing a draft without meaningful field changes MUST NOT update that ordering timestamp.

#### Scenario: Read does not reorder
- **WHEN** the user opens Config's draft list or resumes a draft without editing
- **THEN** that draft's last-modified ordering MUST remain unchanged

### Requirement: Confirmed discard
Discarding an unfinished draft MUST require explicit confirmation. Cancelled discard MUST leave the draft intact. Confirmed discard MUST remove only the selected draft.

#### Scenario: Cancel discard
- **WHEN** the user cancels a discard confirmation
- **THEN** the unfinished draft MUST remain available

#### Scenario: Confirm discard
- **WHEN** the user confirms discard for one draft among several
- **THEN** only that draft MUST be removed

### Requirement: Deleted committed Entry under edit draft
When the committed Entry associated with an edit draft no longer exists, the draft MUST remain as an unfinished draft without a live Entry association. The UI MUST show a banner explaining the Entry is gone. Explicit Save MUST create a new Entry only after the user confirms that outcome, and MUST NOT silently recreate the deleted Entry identity.

#### Scenario: Save after Entry deleted requires confirm
- **WHEN** an edit draft's Entry was deleted and the user attempts Save
- **THEN** the application MUST require confirmation before creating a new Entry from that draft

### Requirement: Changed committed Entry under edit draft
When a committed Entry's stored content differs from what the edit draft was based on (Entry updated elsewhere), Edit resume and final Save MUST warn the user. Save MAY still overwrite the Entry using existing Entry last-write-wins semantics after the warning is shown.

#### Scenario: Warn then allow overwrite
- **WHEN** Entry E was updated after draft D for E was created and the user Saves D
- **THEN** the application MUST warn that the committed Entry changed and MAY persist D onto E without requiring a separate merge tool

### Requirement: Optimistic draft revision control
Unfinished drafts MUST carry a server revision that advances on each successful meaningful write. Clients MUST supply the revision they based edits on when autosaving, finally Saving, or discarding. A request with a stale revision MUST be rejected without applying the write.

#### Scenario: Stale autosave rejected
- **WHEN** two editors load the same draft revision and the first saves a newer revision then the second autosaves with the old revision
- **THEN** the second autosave MUST fail without overwriting the newer server content

#### Scenario: Stale final Save rejected
- **WHEN** a client attempts final Save using a stale draft revision
- **THEN** the application MUST NOT persist the Entry from that stale attempt and MUST NOT overwrite the newer unfinished draft

#### Scenario: Stale discard rejected
- **WHEN** a client attempts Discard using a stale draft revision
- **THEN** the newer draft MUST remain and MUST NOT be deleted by that stale request

### Requirement: Conflict recovery without merge
When a write is rejected as a conflict, the editor MUST keep the user's local Markdown available, show a conflict status, and offer a reload of the server version that replaces the editable field while preserving the local text in a read-only copy surface. The system MUST NOT automatically merge Markdown or provide real-time collaborative editing.

#### Scenario: Reload server keeps local copy
- **WHEN** the user chooses reload after a conflict
- **THEN** the editable draft MUST show the server content and the previously rejected local Markdown MUST remain available to copy from a read-only surface

### Requirement: Idempotent draft creation
The first create of a New or Edit unfinished draft MUST accept a client-generated create identifier. Retrying create with the same identifier after a lost response MUST return the same draft rather than creating a duplicate.

#### Scenario: Lost create response
- **WHEN** the client sends an initial create that succeeds on the server but the response is lost and the client retries with the same create identifier
- **THEN** only one unfinished draft MUST exist for that create identifier

### Requirement: No resurrection after finalize or discard
Autosave or other delayed writes MUST NOT recreate an unfinished draft that has already been successfully committed or discarded. Requests targeting a missing finalized/discarded draft MUST fail without inserting a replacement row unless the user has explicitly started a new draft workflow with a new create identifier.

#### Scenario: Autosave after successful Save
- **WHEN** a draft was removed by successful Entry Save and a delayed autosave for that draft id arrives
- **THEN** the server MUST NOT create a new unfinished draft from that request

#### Scenario: Autosave after discard
- **WHEN** a draft was discarded and a delayed autosave for that draft id arrives
- **THEN** the server MUST NOT recreate that draft