## ADDED Requirements

### Requirement: New Entry always starts fresh
The standard New Entry entry point MUST always start a fresh Entry workflow. It MUST NOT automatically load an existing unfinished draft. Resume of unfinished New drafts MUST occur through the floating Drafts control, Config management, or a draft-specific editor URL.

#### Scenario: New ignores other drafts
- **WHEN** unfinished New drafts exist and the user opens New Entry via Add Entry
- **THEN** the form MUST start empty of those drafts' content (aside from normal defaults such as today's date) until the user edits or explicitly resumes a draft elsewhere

### Requirement: Edit Entry resumes unfinished draft
When the user opens Edit Entry and an unfinished draft exists for that Entry, the editor MUST resume that draft's fields. When none exists, the editor MUST seed from the committed Entry without creating a draft until a meaningful modification occurs.

#### Scenario: Resume edit draft
- **WHEN** draft D exists for Entry E and the user opens Edit for E
- **THEN** title, date, and Markdown MUST come from D
