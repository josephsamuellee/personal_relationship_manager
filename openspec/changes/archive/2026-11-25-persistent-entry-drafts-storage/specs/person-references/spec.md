## MODIFIED Requirements

### Requirement: Unknown person resolution
When no matching Person exists for a wiki reference, the system MUST NOT silently discard the reference and MUST provide a workflow allowing the user to create the Person. That workflow MUST operate against the durable unfinished draft being resolved so Markdown and other draft fields are preserved across resolution actions.

#### Scenario: Unknown person
- **WHEN** no matching Person exists and an Entry draft contains `[[Andrew]]`
- **THEN** the system MUST NOT silently discard the reference and MUST provide a workflow allowing the user to create Andrew while retaining the draft body

### Requirement: Ambiguous person resolution
When multiple People could match a reference, the system MUST require explicit resolution and MUST NOT guess which Person was intended. Explicit selections MUST be retained on the durable unfinished draft until Save succeeds or the draft is discarded.

#### Scenario: Ambiguous person
- **WHEN** multiple People could match a reference and the user attempts to save the Entry
- **THEN** the system MUST require explicit resolution, MUST NOT guess which Person was intended, and MUST keep the selection on the unfinished draft for subsequent Save
