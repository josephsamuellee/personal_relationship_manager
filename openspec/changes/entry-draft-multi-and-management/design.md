# Design

## Context

See proposal.md — Why. Builds on storage + autosave. Today floating Drafts links to `/entries/drafts` (session-era single draft page). Config has no draft section. Approved §11: floating → MRU editor directly; Config owns list; deleted Entry nullify+confirm; changed Entry warn-but-allow-overwrite; resolution UI stays resolve-only.

## Goals / Non-Goals

**Goals**
- Multi New drafts; one edit draft per Entry with Edit resume.
- MRU floating resume; Config list/discard; read without bumping `content_updated_at`.
- Deleted/changed Entry UX per approvals.

**Non-Goals**
- Conflict lock_version UI; autosave internals; expiration/trash; new Drafts app section; changing person-resolution panels beyond draft identity already established.

## Decisions

### 1. Floating control → MRU editor URL
**Choice:** `entry_draft_in_session?` becomes unfinished-draft existence check; link goes to `edit` path of `PersistentEntryDraft.order(content_updated_at: :desc).first`. Remove dependence on `/entries/drafts` as primary UX (redirect that route to MRU or Config).  
**Why:** Approved; no picker in standard flow.  
**Alternatives:** Keep intermediate drafts page (rejected).

### 2. Config Unfinished Drafts partial
**Choice:** Render list on `ConfigController#show`; Resume links to draft editor; Discard uses existing discard endpoint with `draft_id` + `turbo_confirm`. Sort by `content_updated_at DESC`.  
**Why:** Extends Config extensibility requirement.  
**Alternatives:** Separate `/drafts` admin page (out of scope).

### 3. Edit resume
**Choice:** `EntriesController#edit` finds draft by `entry_id`; if present, seed `@draft` from record without touching `content_updated_at`.  
**Why:** Product rule.  
**Alternatives:** Always seed from Entry (loses unfinished work).

### 4. Detect Entry changed under draft
**Choice:** Store optional `entry_updated_at_at_load` snapshot on draft create/first bind OR compare draft metadata to `entries.updated_at` on resume/Save. Prefer persisting `base_entry_updated_at` datetime on the draft row when binding to an Entry (small additive migration if not present). Warn banner when `entry.updated_at != base_entry_updated_at`.  
**Why:** Reliable warn without full Entry revision history.  
**Alternatives:** Hash of Entry body (heavier); skip warn (rejected by §11).

### 5. Deleted Entry
**Choice:** Rely on FK nullify; banner when `entry_id` nil but draft previously was an edit (track `was_edit` via `base_entry_updated_at` present or a boolean `orphaned_edit`). Save requires `confirm_create_new_entry` param.  
**Why:** Approved.  
**Alternatives:** Auto-convert silently (rejected).

### 6. content_updated_at discipline
**Choice:** Only bump on meaningful writes (autosave/Save staging/resolution selection changes). Controllers for show/list/resume use `update_columns`-free reads.  
**Why:** Spec MRU integrity.

## Risks / Trade-offs

- [base_entry_updated_at migration] → Small additive column; document in tasks.  
- [Orphan drafts after Entry delete] → Expected; Config lists them as New-capable with banner.  
- [MRU floating surprises] → Accepted; Config lists all for choice.

## Migration Plan

1. Additive column(s) for Entry-change detection if needed.  
2. Ship Config + floating + Edit resume together.  
3. Redirect legacy `/entries/drafts`.  
4. Rollback: revert UI; drafts remain in DB.

## Open Questions

None — §11 confirmed.
