## MODIFIED Requirements

### Requirement: Duplicate submission protection on Save
Save MUST use best-effort frontend protection against accidental repeated Save actions while a request is in flight. This change MUST NOT introduce server-side Entry idempotency tokens or request-deduplication services for committed Entry Save. Unfinished-draft revision columns and client create identifiers used solely for durable draft concurrency and create idempotency are allowed.

#### Scenario: Repeated Save click while processing
- **WHEN** the user clicks Save and the request is being processed
- **THEN** the Save control SHOULD become temporarily disabled and SHOULD provide a visible saving state where supported by existing Turbo behavior

### Requirement: Concurrent edit last-write-wins
Concurrent edits of the same committed Entry MUST preserve existing last-write-wins update semantics for the Entry record. Unfinished drafts for an Entry MUST use optimistic conflict detection and MUST NOT silently overwrite a newer unfinished draft revision. This change MUST NOT introduce committed Entry revision history, OT, or CRDT merging.

#### Scenario: Concurrent edits
- **WHEN** two browser tabs edit the same Entry and both submit valid changes
- **THEN** existing update semantics MUST apply and the later successful update MAY overwrite earlier changes

#### Scenario: Concurrent committed Entry updates
- **WHEN** two browser tabs edit the same Entry and both submit valid changes without an intervening unfinished-draft conflict
- **THEN** existing Entry update semantics MUST apply and the later successful Entry update MAY overwrite earlier committed changes

#### Scenario: Concurrent unfinished draft updates
- **WHEN** two editors autosave the same unfinished draft and the second uses a stale revision
- **THEN** the stale write MUST be rejected and the newer draft revision MUST remain
