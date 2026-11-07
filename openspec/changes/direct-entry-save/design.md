# Design

## Context

See proposal.md — Why. Today New/Edit forms POST to `create_preview` / `create_preview_update`, which always stage `session[:entry_draft]` and redirect to `show_preview`. Persistence happens only from Preview via `create`/`update`, which load the staged draft and call `EntrySaver.save!` when `valid_for_save?`. `EntryDraft` already exposes `unresolved_people`, `validation_errors`, and `valid_for_save?` (errors empty, no unresolved people, at least one person, date present). Preview already renders validation errors and resolution panels together. Specs for this change live under `specs/entries/` and `specs/markdown-editor/`.

## Goals / Non-Goals

**Goals**
- Make New/Edit Save the primary path: build draft from params, persist when valid, else branch to resolution UI or New/Edit re-render.
- Keep Preview routes and resolution actions (`resolve_person`, `create_person`, `replace_person_name`, discard) working for staged drafts.
- Reuse `EntryDraft` / `EntrySaver` without duplicating parsers or persistence.
- Encode validation precedence: unresolved people → resolution UI (even if other errors exist); recognized people + validation errors → prefer New/Edit re-render.
- Apply relationship changes on direct Save without a blocking diff confirmation.
- Best-effort Turbo submit disable; document accepted multi-tab and duplicate-create limitations.

**Non-Goals**
- New resolution UI, autocomplete, autosave, schema/migrations, multi-draft session keys, optimistic locking, server idempotency.
- Changes to Person About Preview/Save or OverType internals.
- Removing Preview infrastructure entirely (still needed for resolution).

## Decisions

### 1. Point New/Edit forms at create/update
**Choice:** Change `new.html.erb` to `form_with url: entries_path, method: :post` and `edit.html.erb` to `form_with url: entry_path(@entry), method: :patch` (or equivalent), primary submit label **Save**. Remove the Preview submit from those forms. Keep `hidden_field entry[entry_id]` on edit.  
**Why:** Smallest route/view change; reuses existing `create`/`update` endpoints instead of inventing a third action.  
**Alternatives:** New `POST /entries/save` action (unnecessary indirection); keep Preview URL and branch inside `create_preview` (leaves misleading routes/labels).

### 2. Branching inside create/update
**Choice:** Shared private helper conceptually:

```
draft =
  if entry params present for this request
    EntryDraft.from_params(...)
  else
    load_draft_from_session
  end

if draft.nil?
  redirect back to new/edit with alert
elsif draft.unresolved_people.any?
  session[:entry_draft] = draft.to_session
  redirect_to preview_entries_path (existing notice helpers / status)
elsif draft.valid_for_save?
  EntrySaver.save!(draft)
  session.delete(:entry_draft)
  redirect_to entry with success notice
else
  # validation-only failure, people recognized (or none)
  assign @draft = draft; render :new or :edit (status :unprocessable_entity)
end
```

Resolution Save (Preview button) continues to POST/PATCH without body params and uses the session branch. Detect "params present" via `params[:entry]` (title/body/date) rather than inventing a new flag.  
**Why:** Matches product branching; preserves existing Preview Save.  
**Alternatives:** Always stage then auto-persist when valid (extra session write on happy path; rejected by “avoid unnecessary staging”).

### 3. Validation precedence uses unresolved_people first
**Choice:** Check `unresolved_people.any?` before `valid_for_save?` / validation-only re-render. Staging still stores `validation_errors` via `to_session`, so Preview continues to list date/title/person errors beside resolution panels (already implemented).  
**Why:** Explicit product decision; no new UI.  
**Alternatives:** Re-render New/Edit when any validation error exists even with unresolved people (conflicts with precedence decision).

### 4. Relationship diff non-blocking
**Choice:** Do not add a confirmation gate on direct Save. Leave `EntryRelationshipDiff` rendering on `preview.html.erb` for resolution/edit-from-draft paths only.  
**Why:** Spec MODIFIED relationship-changing edits.  
**Alternatives:** Keep mandatory diff on every association change (rejected).

### 5. Keep preview collection/member routes
**Choice:** Retain `GET/POST preview` routes for staging from resolution flows and for any remaining programmatic stage; New/Edit stop posting to them. Member `POST preview` may become unused by primary UI but can remain for compatibility/tests until cleaned up only if nothing else needs it—prefer leaving routes in place this change.  
**Why:** Resolution actions redirect to `preview_entries_path`; discarding Preview routes would break resolution.  
**Alternatives:** Rename Preview to “Resolve” in UI copy only (optional, not required).

### 6. Duplicate submit: Turbo submits-with
**Choice:** On New/Edit Save forms, use Turbo’s disable-with / `data-turbo-submits-with` (or Rails `data: { turbo_submits_with: "Saving..." }` on the submit) so the control disables while the request is in flight. Do not set `data-turbo="false"` on the primary Save form unless a concrete conflict appears (Preview Save historically used `turbo: false`; evaluate whether create/update redirects work under Turbo—existing Preview→Save used non-Turbo; direct Save can stay Turbo-on for disable-with, matching normal `form_with`).  
**Why:** Spec asks for best-effort frontend only.  
**Alternatives:** Custom Stimulus disable (more code); server idempotency (out of scope).

### 7. Flash and success notices
**Choice:** Keep `"Entry saved."` / `"Entry updated."` and existing save-banner behavior on Entry detail after redirect.  
**Why:** Already covered by controller tests and UX.

### 8. No-op Markdown
**Choice:** Rely on existing OverType exact-preservation contract; direct Save posts the same `entry[body_markdown]` field. Update tests that asserted Preview as the submit destination to Save.  
**Why:** No OverType changes needed.

## Risks / Trade-offs

- [create/update must distinguish form Save vs resolution Save] → Branch on presence of `params[:entry]` body fields; add controller tests for both paths.  
- [Validation-only re-render loses OverType mount] → Reuse existing markdown editor partial with `@draft` values; cover failed validation restores Markdown.  
- [Turbo vs non-Turbo inconsistency with Preview Save buttons] → Prefer Turbo on New/Edit Save for disable-with; leave Preview action buttons as-is (`turbo: false`) unless a regression appears.  
- [Multi-tab single `session[:entry_draft]`] → Document accepted limitation; no multi-draft design.  
- [Duplicate creates on retry] → Document; frontend disable only.  
- [Tests still POST preview then create] → Update happy-path tests to single POST/PATCH Save; keep resolution-path coverage via unresolved people.  
- [Baseline conflict: entries required relationship expose-before-persist; markdown-editor required Preview workflow] → Resolved in this change’s deltas; archive merges them into main specs.

## Migration Plan

1. Ship controller branching + form URL/label changes + Turbo disable-with together.  
2. No DB migration; rollback is revert of controller/views/tests.  
3. Existing staged drafts in sessions remain compatible (`to_session` shape unchanged).  
4. After apply, archive so main `entries` / `markdown-editor` specs reflect direct Save.

## Open Questions

- Whether unused member `POST preview` should be removed in a later cleanup (safe to leave for this change).  
- Optional Preview page title/copy tweak from “Preview Entry” to resolution-oriented wording (cosmetic; not required for acceptance).
