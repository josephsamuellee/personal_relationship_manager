## Purpose

Defines wiki-style Person references in Entry Markdown, primary versus secondary associations, uniqueness, ordering, and explicit resolution for unknown or ambiguous People.

## Requirements

### Requirement: Wiki person references
The syntax `[[Person Name]]` MUST represent a Person reference in Entry Markdown.

#### Scenario: Existing person reference
- **WHEN** Andrew already exists and an Entry contains `[[Andrew]]`
- **THEN** the Entry MUST associate with Andrew

### Requirement: Unknown person resolution
When no matching Person exists for a wiki reference, the system MUST NOT silently discard the reference and MUST provide a workflow allowing the user to create the Person.

#### Scenario: Unknown person
- **WHEN** no matching Person exists and an Entry contains `[[Andrew]]`
- **THEN** the system MUST NOT silently discard the reference and MUST provide a workflow allowing the user to create Andrew

### Requirement: Ambiguous person resolution
When multiple People could match a reference, the system MUST require explicit resolution and MUST NOT guess which Person was intended.

#### Scenario: Ambiguous person
- **WHEN** multiple People could match a reference and the user attempts to save the Entry
- **THEN** the system MUST require explicit resolution and MUST NOT guess which Person was intended

### Requirement: Many People per Entry
One Entry MAY reference multiple People. Each referenced Person MUST point to the same Entry. The application MUST NOT duplicate the Entry body to create person-specific copies.

#### Scenario: Shared Entry body
- **WHEN** an Entry references Andrew and Sarah
- **THEN** both People MUST associate with the same Entry record without duplicating the Entry body

### Requirement: Primary Person
The first Person referenced in the Entry's `[[person]]` syntax MUST be the primary Person. Subsequent People MUST be secondary or shared associations.

#### Scenario: Multiple people
- **WHEN** the Entry body contains `Dinner with [[Andrew]] and [[Sarah]].` and the Entry is validated
- **THEN** Andrew MUST be primary and Sarah MUST be associated with the same Entry as a secondary Person

### Requirement: Unique association and order
A Person MUST NOT be associated with the same Entry more than once. The ordering of Person references SHOULD preserve first appearance in the Entry.

#### Scenario: Duplicate wiki mention
- **WHEN** the same Person is referenced twice in one Entry body
- **THEN** the Person MUST appear only once in the Entry's associations and SHOULD keep first-appearance order
