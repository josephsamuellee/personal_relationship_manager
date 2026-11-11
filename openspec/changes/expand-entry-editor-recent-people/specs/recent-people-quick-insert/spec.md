# Spec Delta

## Purpose

Provides a Recent People quick-insert control on New Entry and Edit Entry so writers can insert exact `[[Person]]` wiki references into the Markdown body without typing names or leaving the form.

## ADDED Requirements

### Requirement: Recent People section placement
New Entry and Edit Entry MUST present a Recent People section immediately below the primary Save control when at least one qualifying Person exists.

#### Scenario: Section below Save on New Entry
- **WHEN** the user opens New Entry and at least one Person has been referenced in a saved Entry
- **THEN** a Recent People section MUST appear immediately below the Save control

#### Scenario: Section below Save on Edit Entry
- **WHEN** the user opens Edit Entry and at least one Person has been referenced in a saved Entry
- **THEN** a Recent People section MUST appear immediately below the Save control

### Requirement: Recent People ranking and uniqueness
The section MUST list up to 20 unique existing People ranked by each Person's most recent association to a saved Entry, newest first. Each Person MUST appear at most once. People never associated with any saved Entry MUST be excluded. When fewer than 20 qualify, only those People MUST appear, without placeholders or unrelated names.

#### Scenario: Rank by latest saved-entry association
- **WHEN** saved Entries reference multiple People and the Entry editor loads
- **THEN** up to 20 unique People MUST appear ordered by their latest saved-Entry association, newest first

#### Scenario: Limited history shows exact count
- **WHEN** only seven unique People have been referenced in saved Entries
- **THEN** exactly seven person controls MUST appear without placeholders

#### Scenario: Never-referenced people excluded
- **WHEN** a Person exists but has never been associated with any saved Entry
- **THEN** that Person MUST NOT appear in Recent People

### Requirement: Empty Recent People state
When no People qualify for Recent People, the Entry form MUST omit the Recent People grid and MUST NOT show placeholder names.

#### Scenario: No qualifying people
- **WHEN** the user opens New Entry or Edit Entry and no Person has been referenced in a saved Entry
- **THEN** the Recent People grid MUST be omitted

### Requirement: Recent People layout
On wide viewports the Recent People controls MUST arrange in four columns with at most five rows for a full set of 20. On narrow viewports the layout MUST use responsive columns with touch-friendly targets.

#### Scenario: Desktop four-by-five grid
- **WHEN** twenty qualifying People are shown on a wide viewport
- **THEN** the controls MUST present in four columns and at most five rows

#### Scenario: Mobile responsive columns
- **WHEN** the Entry editor is shown on a narrow touchscreen
- **THEN** Recent People MUST use a responsive column layout with comfortable touch targets

### Requirement: Person controls are insert buttons
Each listed Person MUST render as an accessible button labeled with that Person's name. The control MUST NOT be a navigation hyperlink to the Person page.

#### Scenario: Button not link
- **WHEN** Recent People renders a Person
- **THEN** the control MUST be a button exposing the Person's name and MUST NOT navigate to that Person's page when activated

### Requirement: Insert wiki reference into Markdown body
Activating a Recent People button MUST insert exactly `[[Person Name]]` using that Person's stored name into the Entry Markdown body field. The insertion MUST NOT add whitespace, newlines, or other formatting automatically. Repeated activations MUST be allowed. The control MUST NOT insert into the title or date fields.

#### Scenario: Insert at caret
- **WHEN** the user positions the caret in the Markdown body and activates a Recent People button
- **THEN** exactly `[[Person Name]]` for that Person MUST appear at that caret position

#### Scenario: Replace selection
- **WHEN** the user selects text in the Markdown body and activates a Recent People button
- **THEN** only the selected text MUST be replaced by exactly `[[Person Name]]`

#### Scenario: Append when no usable selection
- **WHEN** no usable editor selection or caret is available and the user activates a Recent People button
- **THEN** exactly `[[Person Name]]` MUST be appended to the Markdown body

#### Scenario: No auto whitespace
- **WHEN** the user activates a Recent People button
- **THEN** the inserted text MUST be exactly `[[Person Name]]` with no added surrounding whitespace or newlines from the insert action

### Requirement: Preserve selection across button interaction
Interacting with a Recent People button MUST preserve the Markdown body's last known caret or selection for the insert action and MUST NOT steal focus in a way that clears that target before insertion.

#### Scenario: Selection survives button press
- **WHEN** the user has a caret or selection in the Markdown body and presses a Recent People button
- **THEN** the insert MUST use that last known caret or selection rather than losing it to the button focus change

### Requirement: No submit or navigation on insert
Activating a Recent People button MUST NOT submit the Entry form, MUST NOT save the Entry, and MUST NOT navigate away from the page.

#### Scenario: Click does not save
- **WHEN** the user activates a Recent People button
- **THEN** the Entry MUST remain unsaved solely due to that activation and the form MUST NOT submit

#### Scenario: Mobile tap does not navigate
- **WHEN** the user taps a Recent People button on a narrow touchscreen
- **THEN** insertion MUST succeed without unintended form submission or navigation

### Requirement: Inserted text participates in Save workflow
Text inserted via Recent People MUST update the same Markdown body value submitted as `entry[body_markdown]`. Direct Save, validation, unknown-person resolution, unsaved draft handling, and last-write-wins semantics MUST remain unchanged. This capability MUST NOT introduce autosave.

#### Scenario: Save includes inserted reference
- **WHEN** the user inserts a person reference via Recent People and saves a valid Entry
- **THEN** the persisted Markdown MUST include that inserted `[[Person Name]]` once per successful insert activation that remained in the body

#### Scenario: Existing workflow intact
- **WHEN** the user edits an Entry that already contains Markdown and person references, inserts additional references via Recent People, and saves
- **THEN** existing Markdown, validation, and direct-save behavior MUST remain intact

#### Scenario: No autosave from insert
- **WHEN** the user inserts a person reference via Recent People without clicking Save
- **THEN** the application MUST NOT persist the Entry solely because of that insert
