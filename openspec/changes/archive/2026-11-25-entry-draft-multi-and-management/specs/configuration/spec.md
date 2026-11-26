## ADDED Requirements

### Requirement: Unfinished Drafts on Config
The Config page MUST include an Unfinished Drafts management section listing all unfinished Entry drafts sorted by most recently modified. Each row MUST show a title or Untitled label, occurrence date when available, last modified time, whether the draft is a new Entry or an edit of an existing Entry, a Resume action, and a Discard action that requires confirmation. Config MUST NOT add automatic draft expiration or a separate dedicated Drafts management page outside Config for this capability.

#### Scenario: List all unfinished drafts
- **WHEN** multiple unfinished drafts exist and the user opens Config
- **THEN** all of them MUST appear in the Unfinished Drafts section ordered by most recent meaningful modification

#### Scenario: Resume from Config
- **WHEN** the user chooses Resume on a listed draft
- **THEN** the application MUST open that draft's editor workflow

#### Scenario: Discard from Config with confirmation
- **WHEN** the user discards a draft from Config and confirms
- **THEN** that draft MUST be removed and other drafts MUST remain
