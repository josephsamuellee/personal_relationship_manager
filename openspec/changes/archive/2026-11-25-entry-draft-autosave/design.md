# Design

## Context

See proposal.md — Why. Depends on `persistent-entry-drafts-storage` (`entry_drafts`, draft-id Preview/Save). Entry forms use Stimulus (`recent-people`, `markdown-editor`, `entry-date`); OverType bubbles `input`. No autosave exists. Approved: 3s idle debounce only (no max-wait), URL `replaceState` after first New create, no localStorage for journal text.

## Goals / Non-Goals

**Goals**
- Stimulus autosave on Entry New/Edit forms with visible statuses and bounded retry.
- Create-on-first-meaningful-edit; PATCH updates thereafter.
- Replace URL to draft editor after first New create.
- Navigation guards for dirty/unacked state; Save flushes latest content.

**Non-Goals**
- Conflict 409 UI (concurrency change); multi-draft Config/floating MRU (management change).
- Max-wait autosave; browser persistent local draft store; Person About autosave; background workers.

## Decisions

### 1. Stimulus `entry-draft-autosave` on the Entry form
**Choice:** New controller on `form.entry-form` listening to bubbled `input`/`change` on title, `entry[raw_date]`, and body textarea (OverType + Recent People already bubble `input`). Debounce 3000ms; compare to `lastAckedSnapshot`; POST create or PATCH update JSON/Turbo.  
**Why:** Fits importmap/Stimulus stack; no new FE framework.  
**Alternatives:** Server-only timers (impossible); pack into `markdown-editor` (wrong coupling to Person About mounts).

### 2. Endpoints
**Choice:** `POST /entry_drafts` (create) and `PATCH /entry_drafts/:id` (update) accepting title, raw_date, body_markdown, optional entry_id, returning `{ id, content_updated_at, lock_version }`. CSRF via existing Rails/Turbo.  
**Why:** Explicit draft API keeps EntriesController Save path clean.  
**Alternatives:** Nest under entries collection only.

### 3. URL replace after first New create
**Choice:** On create ACK, `history.replaceState` to draft editor path (e.g. `/entry_drafts/:id/edit`). Add that route rendering the same New form seeded from the draft. `/entries/new` always blank.  
**Why:** Approved §11; refresh-safe.  
**Alternatives:** Keep `/entries/new?draft_id=` (weaker bookmark semantics).

### 4. Status + retry
**Choice:** Aria-live status text for the five product states needed now (unsaved / saving / saved / retrying). Conflict state reserved for later. Backoff ~2s, 5s, 15s, 30s cap; single latest payload; clear retry on success or user discard/navigation end.  
**Why:** Matches product statuses without concurrency UI yet.  
**Alternatives:** Toast-only (less persistent).

### 5. Navigation protection
**Choice:** `beforeunload` when dirty/unacked; `turbo:before-visit` confirm and best-effort `navigator.sendBeacon` or awaited fetch flush. Explicit Save triggers immediate flush then submits full form fields.  
**Why:** Minimum protection without localStorage.  
**Alternatives:** Block all navigation hard (too aggressive).

### 6. Edit Entry without existing draft
**Choice:** Seed fields from Entry; create draft on first meaningful edit with `entry_id` set (unique constraint from storage change). If a draft already exists for that Entry, storage/multi changes define resume — autosave just PATCHes the bound id when present in the form.  
**Why:** Aligns with “draft only after modification” and one edit draft per Entry.

### 7. content_updated_at
**Choice:** Server bumps `content_updated_at` on successful autosave writes (meaningful). Reads do not.  
**Why:** Prepares MRU ordering for management change.

## Risks / Trade-offs

- [Debounce loss on kill] → Documented; no localStorage by approval.  
- [SQLite write frequency] → Single-user; one write per pause; acceptable on Pi.  
- [Race with explicit Save] → Flush-before-submit; server treats Save params as authoritative.  
- [create without client_create_id] → Duplicate create on lost ACK deferred to concurrency change; autosave SHOULD keep create-in-flight latch to avoid double POST from one tab.

## Migration Plan

1. Requires storage change migrated.  
2. Ship routes + Stimulus + views together.  
3. Rollback: revert FE/routes; drafts table remains.  
4. No data backfill.

## Open Questions

None — product decisions confirmed (§11).
