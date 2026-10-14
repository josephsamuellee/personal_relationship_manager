# Design

## Context

See proposal.md — Why. New Entry and Edit Entry already share a Stimulus `entry-date` controller with a text `entry[raw_date]` field and Use Today. Server initialization uses `EntriesController#initial_raw_date` (`Time.zone.today` or `params[:occurred_on]` ISO date). Persistence and validation remain on `DateParser` / `EntryDraft` / preview-save. No schema change is in scope. Specs live in `specs/entry-date-picker/spec.md`.

Observed gap: Use Today currently formats via the browser's `new Date()` local calendar, not an explicit app-zone source. The picker and Use Today should agree with application timezone expectations from the baseline.

## Goals / Non-Goals

**Goals:**
- Shared compact date row + ISO Monday-first picker on New and Edit Entry.
- Field text remains source of truth; picker keeps temporary view-month/year until day select.
- Client open-init understands the same unambiguous formats users already type (enough to open on the right month) without replacing server validation.
- Zero new gems/npm calendar libraries; stay on Hotwire/Stimulus and existing CSS.

**Non-Goals:**
- Changing `DateParser` accepted formats or save/preview flow.
- Database migrations or new columns.
- Date pickers outside these two forms.
- Perfect offline parity with every Ruby edge case if a tiny shared format subset covers open-init (full validation stays server-side on preview/save).

## Decisions

### 1. Extend Stimulus `entry-date` rather than a third-party picker
**Choice:** Grow `app/javascript/controllers/entry_date_controller.js` to own Use Today, Pick Date toggle, calendar grid, month/year navigation, and day commit into the existing input target.  
**Why:** Already wired on both forms; Pi-friendly; no dependency.  
**Alternatives:** Native `<input type="date">` (weak ISO week UI, fights free-text formats); flatpickr/other npm (heavier, importmap churn).

### 2. Shared ERB partial for the date row
**Choice:** Extract `_occurred_on_field.html.erb` (or similar) used by `new` and `edit`.  
**Why:** Spec requires identical behavior; avoids drift.  
**Alternatives:** Duplicate markup in both views (faster initially, worse consistency).

### 3. Client-side parse for picker open only
**Choice:** Implement a focused JS parser for the formats already accepted by `DateParser` (DD MMM YYYY, DD-MMM-YYYY, YYYYMMDD, YYYY-MM-DD, YYYY-W##-D) used solely to initialize view month/year and to reject open when invalid. Server `DateParser` remains authoritative on preview/save.  
**Why:** Opening the picker is a synchronous UI action; a round-trip endpoint adds latency and complexity for no persistence gain.  
**Alternatives:** JSON endpoint wrapping `DateParser` (perfect parity, extra route/controller); parse only `DD MMM YYYY` (breaks open-init after users type ISO forms).

### 4. Commit format on day select
**Choice:** On day click, write `DD MMM YYYY` (uppercase month abbreviation matching existing `strftime("%d %b %Y")` display) into the field and close the picker.  
**Why:** Matches current edit/new defaults and Use Today output shape.  
**Alternatives:** Preserve whatever format was previously typed (nicer for power users, harder and inconsistent with Use Today).

### 5. Application timezone for “today”
**Choice:** Pass today’s `YYYY-MM-DD` (or formatted string) from the server into the controller via a data attribute on the form/partial so Use Today and “open after Use Today” use app zone, not browser local midnight edge cases.  
**Why:** Aligns with baseline time-zone requirements and date-link init.  
**Alternatives:** Keep browser `new Date()` (simpler, can disagree with `Time.zone` near midnight / travel).

### 6. Calendar rendering
**Choice:** Build a Monday-start grid in JS using `Temporal`-free Date UTC noon tricks or date-only arithmetic carefully; leftmost column shows `W##` via ISO week calculation (week containing year’s first Thursday = W01). Adjacent-month cells muted; selection closes picker. Year dropdown lists a practical range (e.g. entry min year through today+N or fixed span covering historical dates users pick).  
**Why:** Matches ISO requirements without libraries.  
**Alternatives:** CSS-only native picker (cannot meet week-number column requirement cleanly).

### 7. Invalid open UX
**Choice:** On unparsable field text, do not open a month grid that invents a date; keep field text; show an inline error near the row (and/or `aria-invalid`) instructing correction.  
**Why:** Spec forbids silent overwrite.  
**Alternatives:** Open “today” with a warning (conflicts with initialize-from-field MUST).

## Risks / Trade-offs

- [JS/Ruby parse drift] → Mitigation: unit-test JS parse against the same fixture strings as `DateParser` tests; keep server validation as final gate.
- [Timezone mismatch for Use Today] → Mitigation: server-provided today value in data attribute.
- [Accessibility of custom calendar] → Mitigation: keyboard focus on open, Escape closes, buttons labeled, selected day announced; improve iteratively without blocking core scenarios.
- [CSS overflow on narrow phones] → Mitigation: flex wrap on `.occurred-on-row`; calendar as anchored popover that can scroll within viewport.
- [No data migration] → N/A; rollback is revert of views/JS/CSS only.

## Migration Plan

1. Ship partial + Stimulus + CSS behind normal deploy/asset pipeline (importmap pins already cover controllers).
2. No DB migrate; no feature flag required for single-user Pi deploy.
3. Rollback: revert commit / redeploy previous assets; drafts and saved Entries unaffected.

## Open Questions

None that block specs or task breakdown. Year-dropdown span can be chosen at implement time (e.g. 1970–today+10) without changing requirements.
