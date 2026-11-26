# Tasks

## 1. Edit resume and Entry drift

- [x] 1.1 Add additive draft metadata needed to detect committed Entry drift (e.g. `base_entry_updated_at`) and verify migration on test DB
- [x] 1.2 Change Edit Entry to resume the unique unfinished draft for that Entry without bumping `content_updated_at`; verify controller/system test that draft fields load and MRU timestamp is unchanged on GET
- [x] 1.3 Implement deleted-Entry banner + confirmed Save-as-new behavior, and changed-Entry warning on resume/Save while still allowing overwrite; verify both paths with tests

## 2. Floating MRU and legacy drafts page

- [x] 2.1 Point floating Drafts control at the MRU unfinished draft editor and hide when none exist; verify with multiple drafts that click opens the latest by `content_updated_at`
- [x] 2.2 Redirect or retire `/entries/drafts` intermediate page in favor of MRU/Config; verify old path does not strand users on session-era empty copy

## 3. Config Unfinished Drafts

- [x] 3.1 Add Config Unfinished Drafts section listing all drafts (title/Untitled, date, last modified, New vs Edit, Resume, Discard with confirm) sorted by MRU; verify Config controller/view tests for list order, resume link, cancel discard, confirm discard
- [x] 3.2 Verify listing/resume GET does not change `content_updated_at` for displayed drafts

## 4. Multi New draft coexistence

- [x] 4.1 Verify two independent New drafts can coexist via autosave + fresh `/entries/new`, and discarding one leaves the other; align with Add Entry always-fresh scenario

## 5. Integration verification

- [x] 5.1 Run Config, entries, and floating-control related tests against this change’s spec deltas for `persistent-entry-drafts`, `configuration`, `application`, and `entries`

## Workflow follow-up

- Apply after storage + autosave. Next: `entry-draft-concurrency`.
