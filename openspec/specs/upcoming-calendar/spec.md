# upcoming-calendar Specification

## Purpose

Provides the homepage Upcoming Calendar: a two-ISO-week prospective grid of scheduled Google events used to plan interactions and manually seed New Entry, without treating Google as PRM's memory database.

## Requirements

### Requirement: Feature identity
The homepage prospective calendar MUST use the conceptual name Upcoming Calendar. It MUST display scheduled events for planning and Entry seeding. It MUST NOT replace Entries as the authoritative record of what happened.

#### Scenario: Named upcoming calendar section
- **WHEN** the homepage renders its prospective calendar section
- **THEN** the section MUST be presented as Upcoming Calendar rather than as an embedded third-party calendar page

### Requirement: Two ISO week grid
Upcoming Calendar MUST show exactly two complete ISO-8601 weeks: the ISO week containing today in the application time zone, then the immediately following ISO week. Each week MUST have seven columns Monday through Sunday and a left-side week label in `W##` form.

#### Scenario: Standard two-week display
- **WHEN** the application date is Saturday 7 November 2026
- **THEN** Upcoming Calendar MUST show W45 as 02–08 November and W46 as 09–15 November with Monday-first columns

#### Scenario: ISO year boundary
- **WHEN** the application date is 31 December 2026
- **THEN** Upcoming Calendar MUST show ISO week 2026-W53 followed by 2027-W01 including dates that cross the Gregorian year boundary

#### Scenario: Sunday still shows current week
- **WHEN** today is Sunday in the application time zone
- **THEN** Upcoming Calendar MUST still show that Sunday's ISO week as the first row and the next ISO week as the second row

### Requirement: Day cell presentation
Each day cell MUST show the day-of-month as exactly two digits (`01`–`31`). Today's cell MUST use a red outline emphasis that remains visible in both light and dark themes and MUST NOT rely on a solid red background fill as the sole today indicator.

#### Scenario: Today outline
- **WHEN** Upcoming Calendar renders and today falls in the first week
- **THEN** today's cell MUST show a red outline and MUST remain readable under the current light or dark theme

### Requirement: Past days in current week
Days in the current ISO week that are before today MUST remain visible and MUST still show their scheduled events when events are available.

#### Scenario: Midweek past days remain
- **WHEN** today is Wednesday and events exist on that week's Monday
- **THEN** Monday MUST remain on the grid and MUST show those events after a successful fetch

### Requirement: Application timezone authority
Today, ISO week boundaries, and assignment of timed events to day cells MUST use the configured application time zone. The browser time zone and individual Google Calendar time zones MUST NOT determine the displayed calendar date.

#### Scenario: Cross-timezone timed event
- **WHEN** the application time zone is America/Los_Angeles and a timed Google event falls Monday morning in Taiwan but Sunday afternoon in Los Angeles
- **THEN** the event MUST appear on Sunday in Upcoming Calendar

#### Scenario: All-day event date semantics
- **WHEN** Google provides an all-day event for 12 November
- **THEN** the event MUST appear on 12 November regardless of UTC offset conversion that would apply to timed events

#### Scenario: Daylight-saving transition
- **WHEN** a timed event occurs during a daylight-saving transition in the application time zone
- **THEN** the event MUST appear on the correct local calendar date without duplication or omission caused by a fixed UTC offset

### Requirement: Event title chips
After a successful fetch, each day MAY show up to three event title elements. Each visible event MUST be its own activatable control showing the exact Google event title. Titles MUST be shown when the API grants access, without requiring Google public visibility.

#### Scenario: Exact titles
- **WHEN** a day has events titled `Dinner with Jerry` and `Mom call`
- **THEN** those exact titles MUST appear as separate activatable controls for that day

### Requirement: Overflow reveal
When a day has more than three events, the cell MUST show the first three and a `+N more` control for the remainder. Activating `+N more` MUST reveal the remaining events without navigating away from the homepage. Events MUST NOT be silently discarded.

#### Scenario: Five events on one day
- **WHEN** five events fall on one date
- **THEN** the cell MUST show three titles, show `+2 more`, and MUST allow revealing the other two on the homepage

### Requirement: Read-only Google source
Google Calendar MUST be treated as the authoritative source of scheduled-event data for Upcoming Calendar. PRM MUST NOT create, modify, delete, or RSVP to Google events. PRM MUST NOT persist Google events as Entries or relationship records merely because they were displayed.

#### Scenario: Viewing and seeding do not write back
- **WHEN** the user views Upcoming Calendar events or opens New Entry from an event
- **THEN** PRM MUST NOT write any change to Google Calendar

### Requirement: Allowlisted calendars only
When Google is connected, Upcoming Calendar MUST include events only from calendars on the configured allowlist. When the allowlist is empty, the grid MUST still render without events and MUST offer a path to Config calendar selection.

#### Scenario: Selected calendars
- **WHEN** the Google account can access calendars A, B, and C and the allowlist contains A and C
- **THEN** Upcoming Calendar MUST show events from A and C only

#### Scenario: Empty allowlist
- **WHEN** Google authentication is configured and the allowlist is empty
- **THEN** the grid MUST render without events and MUST provide a link to configure calendar selection

### Requirement: Event set for displayed range
Fetches MUST cover the two displayed ISO weeks. Results MUST include recurring occurrences, all-day events, and multi-day events; cancelled events MUST be excluded. Only titles and technical metadata needed for identity, timing, and display MUST be requested or shown. Descriptions, locations, and attendees MUST NOT be displayed.

#### Scenario: Recurring Wednesday
- **WHEN** a recurring Wednesday event exists
- **THEN** each occurrence inside the displayed range MUST appear on its corresponding Wednesday

#### Scenario: Multi-day span
- **WHEN** an event spans 12–14 November inclusive under PRM day-assignment rules
- **THEN** the title MUST appear on 12, 13, and 14 November

#### Scenario: All-day exclusive end
- **WHEN** Google encodes an all-day event with an exclusive end date
- **THEN** PRM MUST map it onto the inclusive local dates that event covers without showing the exclusive end day as an occurrence solely due to that convention

#### Scenario: Timed multi-day overlap
- **WHEN** a timed event interval overlaps multiple application-local calendar dates
- **THEN** the title MUST appear on every overlapped local date

### Requirement: Fresh Google data per visit
Each fresh homepage visit MUST request current Google data for the window rather than presenting a persistent event cache as freshly synchronized. After rename, reschedule, or cancel in Google, a successful fresh fetch MUST reflect the update. Stale in-flight responses MUST NOT corrupt a newer render after Turbo navigation.

#### Scenario: Cancelled elsewhere
- **WHEN** a previously shown event is cancelled in Google and the homepage is visited again with a successful fetch
- **THEN** that event MUST NOT appear as an active event

#### Scenario: Navigation during loading
- **WHEN** a Google request is pending and the user navigates away and returns through Turbo
- **THEN** obsolete responses MUST NOT duplicate event elements or replace the newly rendered calendar with stale data

### Requirement: Deduplicate by reliable identity
When aggregating allowlisted calendars, PRM MUST deduplicate only when reliable Google event identity establishes the same underlying event. Matching titles and dates alone MUST NOT cause deduplication.

#### Scenario: Same event on two calendars
- **WHEN** two selected calendars expose the same underlying Google event identity
- **THEN** Upcoming Calendar MUST show that event once

#### Scenario: Distinct events same title
- **WHEN** two distinct Google events share a title and date but not reliable shared identity
- **THEN** both MUST remain visible

### Requirement: Asynchronous homepage population
The homepage and empty two-week grid MUST render without waiting for Google. Events MUST load asynchronously with a subtle loading indicator, then populate cells on success. Google latency MUST NOT block unrelated homepage sections.

#### Scenario: Slow Google response
- **WHEN** Google takes many seconds to respond
- **THEN** the homepage and calendar grid MUST already be available and events MUST appear when the asynchronous request completes

### Requirement: Graceful Google failure
Authentication errors, API failures, and timeouts MUST leave the grid visible, show an appropriate unavailable, error, or reconnect-required state, and MUST NOT expose credentials or tokens to HTML, JavaScript, logs, or URLs. Core PRM MUST continue working.

#### Scenario: API unavailable
- **WHEN** Google cannot be reached during event fetch
- **THEN** the grid MUST remain visible with an unavailable or error state and the rest of the homepage MUST continue to function

#### Scenario: Reauthorization required
- **WHEN** stored Google authorization can no longer fetch events and reauthorization is required
- **THEN** Upcoming Calendar MUST show a reconnect-required state without exposing credentials to the browser

### Requirement: Date click opens New Entry
Activating a day cell (outside an event control) MUST open the existing New Entry workflow with `occurred_on` set to that date and an empty Markdown body. It MUST NOT persist an Entry by itself.

#### Scenario: Click calendar date
- **WHEN** the user activates 12 November on Upcoming Calendar
- **THEN** New Entry MUST open with `occurred_on` for 12 November and an empty Markdown body

### Requirement: Event click seeds New Entry
Activating a Google event control MUST open the existing New Entry workflow with `occurred_on` set to the clicked cell's date and Markdown body initialized to the exact event title. Description, location, attendees, and time MUST NOT be copied. People MUST NOT be auto-matched or tagged. No Entry MUST be persisted solely by this navigation.

#### Scenario: Click scheduled event
- **WHEN** the user activates an event titled `Dinner with Jerry` in the 12 November cell
- **THEN** New Entry MUST open with `occurred_on` for 12 November and Markdown body exactly `Dinner with Jerry` and MUST NOT auto-link People

#### Scenario: Multi-day event cell date
- **WHEN** `Family Vacation` spans 12–14 November and the user activates it in the 13 November cell
- **THEN** New Entry MUST use 13 November as `occurred_on` and Markdown body `Family Vacation`

#### Scenario: Special characters in title
- **WHEN** an event title contains Unicode, Markdown punctuation, quotes, ampersands, or angle brackets
- **THEN** New Entry MUST receive the original title text without corruption and MUST NOT execute or inject HTML or script from that title

### Requirement: Responsive calendar usability
On narrow viewports, all seven weekdays MUST remain identifiable and event titles MUST remain activatable without becoming impossible to select due to clipping or overlapping controls.

#### Scenario: Narrow mobile viewport
- **WHEN** Upcoming Calendar renders on a narrow mobile viewport
- **THEN** weekday identity and event activation MUST remain available without clipped or overlapped unusable controls

### Requirement: Minimum read scopes
Google integration MUST request only the minimum OAuth scopes needed to read calendar lists and events, and MUST use Google-supported authentication and API mechanisms.

#### Scenario: Scope limited to read
- **WHEN** PRM obtains or refreshes Google authorization for Upcoming Calendar
- **THEN** the authorized scopes MUST be limited to read access for calendar lists and events
