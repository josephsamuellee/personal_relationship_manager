## ADDED Requirements

### Requirement: Autosave observes Entry editor input
On New Entry and Edit Entry, meaningful Markdown edits made through the shared editor (including OverType-enhanced input and Recent People insertions that change the body) MUST mark the Entry draft dirty for autosave. Person About editors MUST NOT gain Entry unfinished-draft autosave behavior from this requirement.

#### Scenario: OverType edit marks dirty
- **WHEN** the user types in the Entry body editor and pauses for the autosave debounce
- **THEN** the durable Entry draft MUST receive the updated Markdown via autosave

#### Scenario: Person About unchanged
- **WHEN** the user edits Person About Markdown
- **THEN** that editing MUST NOT create or update an unfinished Entry draft through Entry autosave behavior
