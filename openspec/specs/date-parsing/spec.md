## Purpose

Defines unambiguous Entry date parsing, canonical YYYY-MM-DD storage, supported formats including ISO week dates, and rejection of ambiguous slash dates.

## Requirements

### Requirement: Canonical date storage
occurred_on MUST represent a calendar date. Canonical representation MUST correspond to YYYY-MM-DD.

#### Scenario: Stored date shape
- **WHEN** a valid Entry date is persisted
- **THEN** occurred_on MUST be stored as a calendar date equivalent to YYYY-MM-DD

### Requirement: Supported unambiguous formats
The Entry date parser MUST accept DD MMM YYYY, DD-MMM-YYYY, YYYYMMDD, YYYY-MM-DD, and YYYY-W##-D. Month names MUST be case-insensitive. ISO week dates MUST follow ISO 8601 semantics.

#### Scenario: Accept common unambiguous forms
- **WHEN** the user enters `09 Aug 2026`, `09-Aug-2026`, `20260809`, `2026-08-09`, or `2026-W32-7`
- **THEN** the parser MUST accept the value as an unambiguous calendar date

### Requirement: Ambiguous dates rejected
The system MUST NOT guess the meaning of ambiguous slash dates. Examples that MUST NOT silently resolve include `08/09/26`, `08/09/2026`, and `9/8/26`. The user MUST instead be prompted to enter an unambiguous date.

#### Scenario: Slash date rejected
- **WHEN** the user enters `08/09/2026` as an Entry date
- **THEN** the system MUST NOT silently resolve the date and MUST prompt for an unambiguous date
