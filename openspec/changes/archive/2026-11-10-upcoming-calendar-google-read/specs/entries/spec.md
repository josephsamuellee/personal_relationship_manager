# Spec Delta

## ADDED Requirements

### Requirement: New Entry body seed from request
When New Entry is opened with a body seed parameter representing Markdown text, and no conflicting staged session draft takes precedence, the Markdown body field MUST initialize to that exact text. The system MUST NOT persist an Entry solely because the body was seeded. Existing Save, validation, person-resolution, and Markdown editor behavior MUST remain unchanged.

#### Scenario: Seeded body from calendar event
- **WHEN** New Entry opens with a body seed of `Dinner with Jerry` and no overriding staged draft
- **THEN** the Markdown editor MUST show exactly `Dinner with Jerry` before the user edits

#### Scenario: Seed does not persist
- **WHEN** New Entry opens with a seeded body and the user leaves without a successful Save
- **THEN** no new Entry MUST be persisted solely because the body was seeded

#### Scenario: Validation keeps seeded values
- **WHEN** New Entry was opened with a selected date and seeded body and Save fails validation
- **THEN** the selected date and Markdown body MUST remain available for correction

#### Scenario: Special character seed integrity
- **WHEN** the body seed contains Unicode, Markdown punctuation, quotes, ampersands, or angle brackets
- **THEN** the editor MUST receive the original text without corruption and MUST NOT treat the seed as executable HTML or script
