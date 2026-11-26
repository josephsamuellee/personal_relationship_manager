# Design

## Context

See proposal.md — Why. Storage may already include `lock_version`; autosave PATCHes drafts; multi-management resumes across devices. Approved conflict UX: replace editor with server version; keep local Markdown in read-only copy surface. No OT/CRDT.

## Goals / Non-Goals

**Goals**
- Enforce `lock_version` on draft update/discard/final Save paths.
- Client create idempotency via unique `client_create_id`.
- 409 conflict handling in API + Stimulus status/recovery UI.
- Prevent delayed autosave resurrection after destroy.

**Non-Goals**
- Merging Markdown; presence/realtime; multi-user auth; changing Entry last-write-wins for committed records beyond warnings already in management change.

## Decisions

### 1. Rails optimistic locking
**Choice:** `PersistentEntryDraft` uses `lock_version`. Updates and destroys that pass a stale version raise / return 409 with current attributes (excluding unnecessary PII in logs). Final Save loads draft with expected version before `EntrySaver` or validates version in the same transaction.  
**Why:** Standard Rails; minimal custom code.  
**Alternatives:** Custom `revision` integer without AR locking (more boilerplate).

### 2. client_create_id
**Choice:** Additive unique nullable string; client UUID on first create; server find-or-create by that key scoped to single-user DB. Clear or leave after create ACK—uniqueness remains for retries.  
**Why:** Fixes lost-response duplicates.  
**Alternatives:** Only in-memory create latch (insufficient across reload).

### 3. Conflict UI
**Choice:** Status “Conflict detected”; banner with Reload server version. Reload sets editor from server payload and shows previous local Markdown in a read-only `<textarea>` or `<pre>` for copy. Stop autosave retries until user reloads or acknowledges.  
**Why:** Approved §11.  
**Alternatives:** Side-by-side merge editor (out of scope).

### 4. No resurrection
**Choice:** PATCH/UPDATE on missing id → 404/410; client clears binding and does not POST create unless user is on a fresh New workflow with a new `client_create_id`. Server create endpoints must not accept “update-shaped” payloads that invent rows for destroyed ids.  
**Why:** Spec requirement.  
**Alternatives:** Soft-delete drafts (rejected — no trash in product).

### 5. Entries baseline amendment
**Choice:** Narrow “no new DB columns” duplicate-submit rule to committed Entry Save; allow draft concurrency columns. Keep Entry LWW; document draft optimistic locking separately.  
**Why:** Resolves baseline conflict explicitly.

## Risks / Trade-offs

- [Users confused by conflicts] → Clear banner + copyable local text.  
- [Save vs autosave version skew] → Save sends current lock_version from last ACK or refreshes before commit; on 409 show same recovery.  
- [Discard race] → Require version on discard.

## Migration Plan

1. Ensure `lock_version` + unique `client_create_id` columns exist.  
2. Ship API 409 + Stimulus together.  
3. Rollback: revert enforcement; columns harmless.

## Open Questions

None.
