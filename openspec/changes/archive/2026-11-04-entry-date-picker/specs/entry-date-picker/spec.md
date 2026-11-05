# Spec Delta

## Purpose

Provides a compact Occurred On control row and ISO 8601 calendar picker on New Entry and Edit Entry while preserving existing date initialization, manual formats, validation, and save behavior.

## ADDED Requirements

### Requirement: Preserve existing date initialization
The system MUST preserve existing initial `occurred_on` values: today for Add Entry, a selected date from homepage or See All Dates links, and the saved date when editing.

#### Scenario: New Entry opened through Add Entry
- **WHEN** the user opens New Entry through the Add Entry control and the page loads
- **THEN** the occurred_on field MUST default to today's date using the application's configured time zone

#### Scenario: New Entry opened through a date link
- **WHEN** the user opens New Entry from a homepage or See All Dates date link representing a specific calendar date
- **THEN** the occurred_on field MUST contain that selected date rather than today's date

#### Scenario: Edit existing entry
- **WHEN** the user opens an existing Entry for editing
- **THEN** the occurred_on field MUST contain that Entry's currently saved date

### Requirement: Compact inline date field
The system MUST display the date label, editable date field, Use Today button, and Pick Date button together in a compact horizontal layout when sufficient width is available, remaining accessible without horizontal page overflow on narrow viewports.

#### Scenario: Desktop layout
- **WHEN** New Entry or Edit Entry renders with sufficient horizontal space
- **THEN** the controls MUST appear on one line in order: Occurred On, editable date field, Use Today, Pick Date

#### Scenario: Narrow viewport
- **WHEN** New Entry or Edit Entry renders with insufficient horizontal space
- **THEN** the controls MUST remain accessible without horizontal page overflow and MAY wrap responsively

### Requirement: Manual date editing remains available
The date field MUST remain manually editable and MUST continue to support all existing accepted date formats. The calendar picker MUST NOT replace existing date parsing or validation rules.

#### Scenario: Manual date editing
- **WHEN** the user edits the date field text using a previously supported unambiguous format
- **THEN** the field MUST accept the edit and later parsing MUST use the existing date rules

### Requirement: Picker initializes from current field value
When the user opens Pick Date, the calendar's displayed month and year MUST initialize from the current occurred_on field text when it parses to a valid date. The system MUST NOT default to the current calendar month when the field already contains a valid date.

#### Scenario: Field contains a historical date
- **WHEN** the date field contains `15 MAR 2020` and today's date is in October 2026 and the user clicks Pick Date
- **THEN** the calendar MUST display March 2020

#### Scenario: Field contains a future date
- **WHEN** the date field contains `25 DEC 2030` and the user clicks Pick Date
- **THEN** the calendar MUST display December 2030

#### Scenario: Field initialized from a date link
- **WHEN** New Entry was opened from a link for `2025-06-12` and the user clicks Pick Date
- **THEN** the calendar MUST display June 2025

#### Scenario: User manually changes the date before opening the picker
- **WHEN** the user changes the field from `13 OCT 2026` to `07 FEB 2019` and then clicks Pick Date
- **THEN** the calendar MUST display February 2019

#### Scenario: Reopening the picker after browsing another month
- **WHEN** the user previously browsed another month, closed the picker, left a valid date in the field, and reopens Pick Date
- **THEN** the calendar MUST initialize from the current field value rather than the previously browsed month

### Requirement: ISO 8601 calendar layout
The open calendar MUST use Monday-first weeks, show month and year with previous and next month controls and a scrollable year dropdown, and show ISO 8601 week numbers in `W##` form in the leftmost column.

#### Scenario: Calendar header
- **WHEN** the calendar picker is open
- **THEN** the first header row MUST display the selected month and year with previous-month and next-month navigation and a scrollable year dropdown

#### Scenario: Weekday headers
- **WHEN** the weekday header renders
- **THEN** weekday columns MUST be ordered Monday through Sunday

#### Scenario: ISO week number column
- **WHEN** calendar weeks render
- **THEN** the leftmost column MUST display each week's ISO 8601 week number in `W##` form using Monday-start weeks where week 01 contains the year's first Thursday

#### Scenario: Calendar crosses a year boundary
- **WHEN** a displayed calendar week spans December and January
- **THEN** the week number MUST use the correct ISO week-year calculation rather than assuming the Gregorian calendar year alone

### Requirement: Month and year navigation without premature commit
Users MUST be able to navigate months and select years without changing the occurred_on field until a specific calendar day is selected.

#### Scenario: Navigate to previous month
- **WHEN** October 2026 is displayed and the user clicks the previous-month control
- **THEN** September 2026 MUST be displayed and the occurred_on field MUST remain unchanged

#### Scenario: Navigate to next month across a year boundary
- **WHEN** December 2026 is displayed and the user clicks the next-month control
- **THEN** January 2027 MUST be displayed

#### Scenario: Select a year
- **WHEN** October 2026 is displayed and the user selects 2020 from the year dropdown
- **THEN** October 2020 MUST be displayed and the occurred_on field MUST remain unchanged

#### Scenario: Browse without selecting a date
- **WHEN** the calendar is open and the user navigates between months or years
- **THEN** the date field MUST NOT change until the user explicitly selects a day

### Requirement: Adjacent-month dates
The calendar MUST show adjacent-month dates needed to complete Monday–Sunday week rows, with muted styling, and selecting such a date MUST update the field and close the picker.

#### Scenario: Adjacent-month date display
- **WHEN** October 2026 is displayed and its first week includes September dates
- **THEN** those September dates MUST appear in their cells with visually muted styling

#### Scenario: Select an adjacent-month date
- **WHEN** October 2026 is displayed and the user selects September 30
- **THEN** the occurred_on field MUST update to September 30, 2026 and the calendar MUST close immediately

### Requirement: Calendar date selection
Selecting a calendar day MUST update the occurred_on field to that date in display form `DD MMM YYYY`, close the picker, highlight the currently selected day when opening on that month, and MUST NOT save the Entry automatically.

#### Scenario: Select a date
- **WHEN** the calendar shows October 2026 and the user selects October 20
- **THEN** the date field MUST display `20 OCT 2026` and the calendar MUST close immediately

#### Scenario: Highlight currently selected date
- **WHEN** the field contains a valid date and the calendar opens to that date's month
- **THEN** the corresponding day MUST be visually distinguished as the currently selected date

#### Scenario: Date selection does not save the entry
- **WHEN** the user selects a date from the calendar and the calendar closes
- **THEN** only the form field value MUST change and the Entry MUST NOT be saved automatically

### Requirement: Use Today behavior
The system MUST preserve Use Today on New Entry and Edit Entry: it updates the field to today's date in the application time zone without saving, and a subsequent Pick Date opens today's month and year.

#### Scenario: Use Today updates the field
- **WHEN** the date field contains a date other than today and the user clicks Use Today
- **THEN** the field MUST update to today's date using the application's configured time zone and the Entry MUST NOT be saved automatically

#### Scenario: Open picker after Use Today
- **WHEN** the user clicks Use Today and then clicks Pick Date
- **THEN** the calendar MUST open to today's month and year

### Requirement: Invalid field text on picker open
When Pick Date is clicked and the field text cannot be parsed into a valid date, the system MUST NOT silently overwrite that text and MUST indicate that the date must be corrected before the picker can initialize from it.

#### Scenario: Invalid date text
- **WHEN** the date field contains unparsable text and the user clicks Pick Date
- **THEN** the system MUST NOT silently overwrite the invalid text and MUST indicate that the date must be corrected before the picker can initialize from it

#### Scenario: Valid supported manual date format opens picker
- **WHEN** the user enters any existing supported unambiguous format and opens Pick Date
- **THEN** the calendar MUST display the parsed date's month and year using existing date parsing rules

#### Scenario: Existing save validation
- **WHEN** the date field contains an invalid value and the user attempts to save
- **THEN** existing date validation MUST reject the value and the Entry MUST NOT be persisted with an invalid occurred_on

### Requirement: Shared New Entry and Edit Entry behavior
Date field and calendar picker behavior MUST be consistent on New Entry and Edit Entry. On Edit Entry, the persisted Entry date MUST remain unchanged until a successful save.

#### Scenario: New Entry
- **WHEN** the user creates a new Entry and interacts with the date field and picker
- **THEN** all date field and picker requirements in this capability MUST apply

#### Scenario: Edit Entry
- **WHEN** the user edits an existing Entry and interacts with the date field and picker
- **THEN** all date field and picker requirements MUST apply and the persisted Entry date MUST remain unchanged until the user saves successfully

### Requirement: Preserve unrelated entry behavior
This change MUST NOT alter unrelated Entry behavior: persistence continues through existing occurred_on workflow without a new date column; date links keep initializing the field; title, body, people, tags, validation, preview, and save workflows remain unchanged.

#### Scenario: Entry persistence
- **WHEN** the user selects or manually enters a valid date and saves
- **THEN** the system MUST persist the date through the existing occurred_on workflow without requiring an additional date-specific database schema

#### Scenario: Existing date links
- **WHEN** a homepage or See All Dates link opens New Entry with a selected date after this feature is enabled
- **THEN** the link MUST continue to initialize the date field correctly

#### Scenario: Other entry fields
- **WHEN** the user uses the date picker while creating or editing an Entry
- **THEN** title, body, people associations, tags, validation, preview, and save workflow behavior MUST remain unchanged
