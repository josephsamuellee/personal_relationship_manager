## MODIFIED Requirements

### Requirement: Global Add Entry control
Normal application pages MUST expose an Add Entry control. The established UI places this as a floating control in the lower-right area. Selecting it MUST navigate to Entry creation as a fresh workflow that does not auto-load an existing unfinished draft. Floating controls MUST NOT permanently obscure page content.

#### Scenario: Add Entry from homepage
- **WHEN** the user selects the floating Add Entry control on a normal application page
- **THEN** the application MUST navigate to Entry creation as a fresh workflow that does not auto-load an existing unfinished draft

## ADDED Requirements

### Requirement: Floating Drafts resumes most recent
When unfinished Entry drafts exist, the floating Drafts control MUST be visible and MUST resume the single most recently modified unfinished draft's editor directly without an intermediate draft-picker step in the standard workflow. When no unfinished drafts exist, the control MUST be hidden.

#### Scenario: Floating control opens MRU draft
- **WHEN** multiple unfinished drafts exist and the user clicks the floating Drafts control
- **THEN** the application MUST open the editor for the draft with the latest meaningful modification time

#### Scenario: Hidden when empty
- **WHEN** no unfinished drafts exist
- **THEN** the floating Drafts control MUST NOT be shown
