## ADDED Requirements

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
