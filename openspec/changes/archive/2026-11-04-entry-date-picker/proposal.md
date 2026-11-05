# Proposal

## Why

Manual Entry date entry is flexible but slow for browsing historical or future months. New Entry and Edit Entry already share an editable `occurred_on` text field and Use Today control; they need a compact inline layout and an ISO 8601 calendar picker that initializes from the field's current value without changing parsing, validation, or save behavior.

## What Changes

- Compact horizontal layout for Occurred On label, editable date field, Use Today, and Pick Date on New Entry and Edit Entry (responsive wrap on narrow viewports).
- Interactive Monday-first calendar with ISO week numbers (`W##`), month arrows, and a scrollable year dropdown.
- Picker display state initializes from the current field text on each open; browsing months/years does not change the field until a day is selected.
- Adjacent-month days complete week rows; selecting one updates the field and closes the picker.
- Invalid field text must not be silently overwritten when opening the picker; existing `DateParser` rules and explicit Save workflow stay in force.
- No schema, routing, or supported-format changes.

## Capabilities

### New Capabilities
- `entry-date-picker`: Compact Occurred On controls and ISO 8601 calendar picker shared by New Entry and Edit Entry, including initialization from the field value, navigation without premature commits, adjacent-month cells, and invalid-input handling at open time.

### Modified Capabilities
- (none) — `date-parsing` and `entries` baseline requirements for formats, validation, preview/save, and date-link initialization remain in force; this change adds UI behavior rather than altering those contracts.

## Impact

- Views: `app/views/entries/new.html.erb`, `app/views/entries/edit.html.erb` (and any shared partial extracted for the date field).
- Stimulus: extend `app/javascript/controllers/entry_date_controller.js` (today control already present; picker is new client-side UI).
- Styles: `app/assets/stylesheets/application.css` for compact row and calendar chrome.
- Parsing remains server-side via `DateParser` / `EntryDraft`; picker may need a small client-side parse aligned with existing formats for open/init, or a lightweight endpoint — design will choose without adding a DB column.
- Tests: controller/system or Stimulus-focused coverage for layout hooks, picker init, selection, and invalid open behavior; existing date-parser and entry save tests should stay green unchanged.
- Out of scope relative to baseline: schema, AI, multi-user, photo, calendar write/import, and date pickers outside New/Edit Entry forms.
