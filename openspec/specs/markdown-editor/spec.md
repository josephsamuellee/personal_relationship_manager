# markdown-editor Specification

## Purpose

Provides a shared Markdown editing surface with toolbar and keyboard shortcuts for Entry body and Person about fields while submitting and exactly preserving raw Markdown, including wiki person links and hashtags, under Turbo navigation.

## Requirements

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

### Requirement: Person about Markdown editor
The Person page About field MUST use the same shared Markdown editor for about Markdown while remaining compatible with the existing About Preview toggle and About save action.

#### Scenario: About editor on Person page
- **WHEN** the user opens a Person page
- **THEN** the About Markdown field MUST be editable through the shared Markdown editor with toolbar and keyboard shortcuts available

#### Scenario: About Preview toggle still works
- **WHEN** the user uses the existing About Preview control
- **THEN** the application MUST continue to support toggling About preview without requiring a redesign of that control

#### Scenario: About validation error restores content
- **WHEN** About save fails validation and the Person page re-renders
- **THEN** the About Markdown the user submitted MUST still be present in the About editor field

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

### Requirement: Theme alignment
The Markdown editor MUST follow the application's current light or dark theme on Entry and Person pages without introducing a separate theme preference for the editor.

#### Scenario: Dark theme editor
- **WHEN** the application theme is Dark and the user opens New Entry, Edit Entry, or a Person About editor
- **THEN** the Markdown editor MUST render using a dark-compatible appearance

#### Scenario: Light theme editor
- **WHEN** the application theme is Light and the user opens those editors
- **THEN** the Markdown editor MUST render using a light-compatible appearance

### Requirement: Page-local editor loading
The Markdown editor library MUST load only on pages that present an editor mount. An importmap pin is allowed, but the library MUST NOT be eagerly imported or preloaded on unrelated pages as part of normal navigation.

#### Scenario: Homepage does not load editor library
- **WHEN** the user opens the homepage
- **THEN** the Markdown editor library MUST NOT be fetched or executed as a requirement of that page

#### Scenario: Editor page loads library when mounting
- **WHEN** the user opens New Entry, Edit Entry, or a Person page with About editing
- **THEN** the Markdown editor library MAY load as needed to initialize the editor mount

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
