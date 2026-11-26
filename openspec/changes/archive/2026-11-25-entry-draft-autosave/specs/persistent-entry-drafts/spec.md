## ADDED Requirements

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
