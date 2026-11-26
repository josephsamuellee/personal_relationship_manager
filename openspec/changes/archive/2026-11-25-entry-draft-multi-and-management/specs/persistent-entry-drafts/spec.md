## ADDED Requirements

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
