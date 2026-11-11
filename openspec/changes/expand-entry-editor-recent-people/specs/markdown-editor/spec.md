# Spec Delta

## MODIFIED Requirements

### Requirement: Entry body Markdown editor
New Entry and Edit Entry MUST present the body field using the shared Markdown editor with formatting toolbar and keyboard shortcuts. The visible Markdown editing area on those Entry pages MUST be approximately twice the previous Entry body editor height. Person About editor height MUST remain unchanged by this requirement.

#### Scenario: New Entry body editor
- **WHEN** the user opens New Entry
- **THEN** the Markdown body field MUST be editable through the shared Markdown editor with a formatting toolbar available

#### Scenario: Edit Entry body editor
- **WHEN** the user opens Edit Entry for an existing Entry
- **THEN** the Markdown body field MUST be editable through the shared Markdown editor and MUST load that Entry's current body Markdown

#### Scenario: Entry editor height roughly doubles
- **WHEN** the user opens New Entry or Edit Entry and the Markdown editor loads
- **THEN** the visible Markdown editing area MUST be approximately twice its previous Entry body height

#### Scenario: Person About height unchanged
- **WHEN** the user opens a Person page About editor
- **THEN** the About Markdown editor visible height MUST NOT be doubled solely because Entry body height increased

### Requirement: No graphical wiki or tag enhancements
The Markdown editor MUST NOT add autocomplete, chips, automatic linking UI, or custom graphical rendering that rewrites `[[Person]]` references or hashtags into non-Markdown controls. Typed wiki links and hashtags MUST remain editable as literal Markdown. New Entry and Edit Entry MAY expose Recent People insert buttons that place exact `[[Person Name]]` text into the body. Person About MUST NOT present that Recent People UI. Using Recent People MUST NOT be required to author person references.

#### Scenario: Wiki links remain literal Markdown
- **WHEN** the user types `[[Sarah]]` in the Entry body editor
- **THEN** the content MUST remain editable as literal Markdown text without a separate person-picker control being required for that input

#### Scenario: Entry pages may offer Recent People insert
- **WHEN** the user opens New Entry or Edit Entry
- **THEN** the page MAY present Recent People insert buttons that insert exact `[[Person Name]]` Markdown into the body without converting existing wiki tokens into chips or non-Markdown controls

#### Scenario: Person About has no Recent People UI
- **WHEN** the user opens a Person page About editor
- **THEN** the About editor MUST NOT present the Entry Recent People quick-insert section
