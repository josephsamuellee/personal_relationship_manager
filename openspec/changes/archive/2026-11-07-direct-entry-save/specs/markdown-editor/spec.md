# Spec Delta

## MODIFIED Requirements

### Requirement: Raw Markdown form submission
The editor MUST submit the authored content as raw Markdown through the existing form field names so Entry Save and Person About save continue to receive Markdown strings, not HTML or another rich-text format. Native required-field validation and form submission semantics MUST remain intact. The implementation MUST NOT maintain two competing named Markdown fields for the same logical input.

#### Scenario: Entry Preview receives Markdown
- **WHEN** the user edits the Entry body in the editor and submits Save
- **THEN** the request MUST include `entry[body_markdown]` as Markdown text reflecting the editor content

#### Scenario: About save receives Markdown
- **WHEN** the user edits About in the editor and saves About
- **THEN** the request MUST include the About Markdown field as Markdown text reflecting the editor content

#### Scenario: Required body still enforced
- **WHEN** New Entry or Edit Entry is submitted with an empty body field
- **THEN** the existing required-field behavior MUST still prevent or reject empty body submission as it does for the native textarea today

### Requirement: Exact Markdown string preservation on no-op
When the editor is initialized with a Markdown string and the user makes no modifications, the Markdown submitted from that field MUST equal that initial browser-side Markdown string exactly, including whitespace and trailing newlines. The editor MUST NOT introduce Markdown normalization or serialization that changes an unmodified value.

#### Scenario: No-op Entry Preview preserves exact body
- **WHEN** Edit Entry initializes the body editor from existing Markdown and the user submits Save without modifying the body
- **THEN** the submitted `entry[body_markdown]` MUST equal the initial browser-side Markdown string exactly

#### Scenario: No-op preserves whitespace and trailing newlines
- **WHEN** the initial browser-side body Markdown contains significant trailing newlines or internal whitespace and the user submits without edits
- **THEN** those whitespace characters MUST appear unchanged in the submitted Markdown

### Requirement: Preserve wiki person links and hashtags
Loading, ordinary editing of unrelated text, and submitting through the editor MUST preserve `[[Person Name]]` wiki links and `#tag` hashtags in the Markdown text. The editor MUST NOT rewrite those tokens into another representation as a side effect of initialization or a no-op submit.

#### Scenario: Load existing wiki link and hashtag
- **WHEN** an Entry body contains `[[Andrew Hsiao]]` and `#church` and the user opens Edit Entry
- **THEN** those exact token forms MUST appear in the editable Markdown content

#### Scenario: Unrelated edit preserves wiki link
- **WHEN** the body contains `[[Andrew Hsiao]]` and the user edits unrelated surrounding text then submits Save
- **THEN** the submitted Markdown MUST still contain `[[Andrew Hsiao]]` unchanged

#### Scenario: Unrelated edit preserves hashtag
- **WHEN** the body contains `#dinner` and the user edits unrelated surrounding text then submits Save
- **THEN** the submitted Markdown MUST still contain `#dinner` unchanged

### Requirement: Toolbar and keyboard shortcuts
The editor MUST expose a formatting toolbar and keyboard shortcuts for common Markdown actions including bold, italic, headings, unordered lists, ordered lists, and links, without requiring the user to type the underlying markers manually for those actions.

#### Scenario: Apply bold from toolbar or shortcut
- **WHEN** the user selects text in the Entry body editor and applies bold via toolbar or keyboard shortcut then submits Save
- **THEN** the submitted Markdown MUST include bold markup for that selection

#### Scenario: Insert list from toolbar or shortcut
- **WHEN** the user applies an unordered or ordered list action via toolbar or keyboard shortcut then submits Save
- **THEN** the submitted Markdown MUST include corresponding list syntax

### Requirement: Turbo navigation lifecycle
Editor mounts MUST remain safe under the application's existing Turbo-driven browser navigation. Navigating away and back MUST NOT leave duplicate editor instances, duplicate event handlers, or lose unsaved Markdown solely because of teardown or reinitialization. Exactly one active editor instance MUST exist per editor mount while that mount is on the page.

#### Scenario: New Entry to Preview and back
- **WHEN** the user opens New Entry, enters unsaved Markdown, Save routes to the person-resolution UI, then the user uses browser Back to return to New Entry
- **THEN** the application MUST preserve the browser's existing navigation/restoration behavior for that form content and MUST show exactly one editor instance on the returned page without duplicate handlers

#### Scenario: Edit Entry to Preview and back
- **WHEN** the user opens Edit Entry, changes Markdown without submitting, Save routes to the person-resolution UI, then the user uses browser Back to return to Edit Entry
- **THEN** the returned page MUST present exactly one editor instance and MUST NOT lose the unsaved Markdown solely due to editor teardown or reinitialization beyond what the browser/Turbo already restore for the form

#### Scenario: Repeated editor and non-editor navigation
- **WHEN** the user repeatedly navigates between an editor page and a non-editor page such as Home
- **THEN** each visit to the editor page MUST initialize at most one active editor instance per mount and non-editor pages MUST NOT retain active editor instances or handlers

### Requirement: Entry Preview workflow unchanged
New Entry and Edit Entry Markdown submission MUST target the Entry Save path as the primary form destination. Valid Entry persistence MAY occur from that Save submission when the draft satisfies all save conditions. When Save requires person resolution, the existing resolution workflow MUST remain available afterward. This capability MUST NOT restore a mandatory Preview-before-Save step for recognized, valid drafts.

#### Scenario: Preview still required before Entry persist
- **WHEN** the user edits an Entry body with the Markdown editor and submits Save with unresolved or ambiguous people
- **THEN** the application MUST reuse the existing person-resolution workflow and MUST NOT persist solely because the editor submitted

#### Scenario: Valid editor Save may persist
- **WHEN** the user edits an Entry body with the Markdown editor and submits Save with a fully valid draft of recognized people
- **THEN** the submission MUST follow the Entry Save path and MAY persist the Entry in that request without a mandatory intermediate Preview step
