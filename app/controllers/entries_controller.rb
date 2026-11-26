class EntriesController < ApplicationController
  before_action :set_entry, only: [ :show, :edit, :update, :create_preview_update ]
  before_action :load_recent_people, only: [ :new, :edit ]

  def new
    if params[:draft_id].present?
      @persistent_draft = PersistentEntryDraft.find_by(id: params[:draft_id])
      @draft = if @persistent_draft
        EntryDraft.from_record(@persistent_draft)
      else
        EntryDraft.new(raw_date: initial_raw_date, body_markdown: initial_body_markdown)
      end
      @orphaned_edit_warning = @persistent_draft&.orphaned_edit?
    else
      @draft = EntryDraft.new(raw_date: initial_raw_date, body_markdown: initial_body_markdown)
    end
    @autofocus_title = params[:occurred_on].present?
  end

  def create
    draft = draft_for_save(entry_id: nil)
    handle_save_attempt(draft, action: :create)
  end

  def show_preview
    draft = load_draft_for_preview
    unless draft
      redirect_to new_entry_path, alert: "No draft to preview. Start a new entry."
      return
    end

    assign_preview_variables(draft)
    render :preview
  end

  def create_preview
    draft = EntryDraft.from_params(entry_params)
    attach_draft_id!(draft)
    stage_persistent_draft!(draft)
    redirect_to preview_entries_path(draft_id: draft.persistent_draft_id), notice: preview_notice_for(draft)
  end

  def create_preview_update
    draft = EntryDraft.from_params(entry_params.merge(entry_id: @entry.id))
    attach_draft_id!(draft)
    stage_persistent_draft!(draft)
    redirect_to preview_entries_path(draft_id: draft.persistent_draft_id), notice: preview_notice_for(draft)
  end

  def show
  end

  def edit
    record = PersistentEntryDraft.find_by(entry_id: @entry.id)
    if record
      @draft = EntryDraft.from_record(record)
      @persistent_draft = record
      @entry_changed_warning = record.entry_changed?
    else
      @draft = EntryDraft.new(
        title: @entry.title,
        raw_date: @entry.occurred_on.strftime("%d %b %Y"),
        body_markdown: @entry.body_markdown,
        entry_id: @entry.id
      )
      @draft.parse!
    end
  end

  def update
    draft = draft_for_save(entry_id: @entry.id)
    handle_save_attempt(draft, action: :update)
  end

  def resolve_person
    record = find_persistent_draft!
    return unless record

    selections = record.person_selections_hash
    selections[params[:name]] = params[:person_id].to_s
    record.person_selections = selections
    record.content_updated_at = Time.current
    record.save!

    redirect_to preview_entries_path(draft_id: record.id), notice: "Selected #{params[:name]}."
  end

  def create_person
    record = find_persistent_draft!
    return unless record

    person = Person.create!(name: params[:name])
    selections = record.person_selections_hash
    selections[params[:name]] = person.id.to_s
    record.person_selections = selections
    record.content_updated_at = Time.current
    record.save!

    redirect_to preview_entries_path(draft_id: record.id), notice: "Created and linked #{person.name}."
  end

  def replace_person_name
    record = find_persistent_draft!
    return unless record

    draft = EntryDraft.from_record(record)
    old_name = params[:name]
    new_name = params[:replacement]
    draft.replace_person_link!(old_name, new_name)
    draft.persist!

    redirect_to preview_entries_path(draft_id: draft.persistent_draft_id), notice: "Changed all \"#{old_name}\" to \"#{new_name}\"."
  end

  def drafts
    record = PersistentEntryDraft.most_recent
    if record
      redirect_to edit_entry_draft_path(record)
    else
      redirect_to config_path, notice: "No unfinished drafts."
    end
  end

  def discard_draft
    record = PersistentEntryDraft.find_by(id: params[:draft_id]) if params[:draft_id].present?
    record ||= PersistentEntryDraft.most_recent
    destination = safe_discard_redirect(params[:return_to])

    unless record
      redirect_to destination, notice: "Draft discarded."
      return
    end

    if params[:lock_version].present?
      record.apply_expected_lock_version!(params[:lock_version])
    end

    begin
      record.destroy!
      redirect_to destination, notice: "Draft discarded."
    rescue ActiveRecord::StaleObjectError
      if request.format.json?
        render json: record.reload.conflict_payload(edit_url: edit_entry_draft_path(record)), status: :conflict
      else
        redirect_to edit_entry_draft_path(record.reload), alert: "Conflict detected. This draft changed elsewhere; discard was rejected."
      end
    end
  end

  private

  def set_entry
    @entry = Entry.includes(:primary_person, :people, :tags).find(params[:id])
  end

  def entry_params
    params.require(:entry).permit(
      :title, :raw_date, :occurred_on, :body_markdown, :entry_id, :draft_id,
      :lock_version, :confirm_create_new_entry, person_selections: {}
    )
  end

  def entry_form_submitted?
    params[:entry].present?
  end

  def draft_for_save(entry_id:)
    if entry_form_submitted?
      attrs = entry_params.except(:draft_id, :confirm_create_new_entry, :lock_version)
      attrs = attrs.merge(entry_id: entry_id) if entry_id.present?
      draft = EntryDraft.from_params(attrs)
      attach_draft_id!(draft)
      draft
    else
      load_draft_for_preview
    end
  end

  def attach_draft_id!(draft)
    draft_id = params.dig(:entry, :draft_id).presence || params[:draft_id].presence
    draft.persistent_draft_id = draft_id.to_i if draft_id.present?
  end

  def handle_save_attempt(draft, action:)
    if draft.nil?
      if action == :create
        redirect_to new_entry_path, alert: "No draft found. Please create an entry first."
      else
        redirect_to edit_entry_path(@entry), alert: "No draft found. Please edit your entry first."
      end
      return
    end

    if action == :update && draft.entry_id.present? && draft.entry_id.to_i != @entry.id
      redirect_to edit_entry_path(@entry), alert: "Draft does not match this entry."
      return
    end

    if action == :create && orphaned_edit_draft?(draft) && !confirm_create_new_entry?
      @draft = draft
      @persistent_draft = PersistentEntryDraft.find_by(id: draft.persistent_draft_id)
      @orphaned_edit_warning = true
      flash.now[:alert] = "The original Entry no longer exists. Confirm to save this draft as a new Entry."
      load_recent_people
      render :new, status: :unprocessable_entity
      return
    end

    if (conflict_record = draft_lock_conflict(draft))
      handle_draft_lock_conflict(conflict_record, draft, action)
      return
    end

    if draft.unresolved_people.any?
      stage_persistent_draft!(draft)
      redirect_to preview_entries_path(draft_id: draft.persistent_draft_id), notice: preview_notice_for(draft)
      return
    end

    if draft.valid_for_save?
      begin
        changed = entry_changed_for_draft?(draft)
        entry = save_entry_and_cleanup_draft!(draft)
        notice = action == :create ? "Entry saved." : "Entry updated."
        notice = "#{notice} The committed Entry had changed since this draft was started." if changed && action == :update
        redirect_to entry_path(entry), notice: notice
      rescue ArgumentError, ActiveRecord::ActiveRecordError => e
        flash.now[:alert] = "Could not save entry: #{e.message}"
        @draft = draft
        render_save_failure(action)
      end
      return
    end

    if draft.persistent_draft_id.present?
      stage_persistent_draft!(draft)
    end

    @draft = draft
    flash.now[:alert] = "Could not save entry. Please fix the issues below."
    render_save_failure(action)
  end

  def expected_draft_lock_version
    raw = params.dig(:entry, :lock_version).presence || params[:lock_version].presence
    raw&.to_i
  end

  def draft_lock_conflict(draft)
    return if draft.persistent_draft_id.blank?

    record = PersistentEntryDraft.find_by(id: draft.persistent_draft_id)
    return unless record

    expected = expected_draft_lock_version
    return if expected.nil?
    return if expected == record.lock_version

    record
  end

  def handle_draft_lock_conflict(record, draft, action)
    if request.format.json?
      render json: record.conflict_payload(edit_url: edit_entry_draft_path(record)), status: :conflict
      return
    end

    @draft = draft
    @persistent_draft = record
    @draft_conflict = true
    @entry_changed_warning = record.entry_changed? if record.entry_id.present?
    @orphaned_edit_warning = record.orphaned_edit?
    flash.now[:alert] = "Conflict detected. This draft changed elsewhere. Reload the server version before saving."
    load_recent_people
    render_save_failure(action)
  end

  def orphaned_edit_draft?(draft)
    return false if draft.persistent_draft_id.blank?

    record = PersistentEntryDraft.find_by(id: draft.persistent_draft_id)
    record&.orphaned_edit?
  end

  def confirm_create_new_entry?
    ActiveModel::Type::Boolean.new.cast(params.dig(:entry, :confirm_create_new_entry))
  end

  def entry_changed_for_draft?(draft)
    return false if draft.persistent_draft_id.blank?

    PersistentEntryDraft.find_by(id: draft.persistent_draft_id)&.entry_changed?
  end

  def safe_discard_redirect(return_to)
    return config_path if return_to == "config"
    return homepage_path if return_to == "homepage"

    new_entry_path
  end

  def save_entry_and_cleanup_draft!(draft)
    Entry.transaction do
      entry = EntrySaver.save!(draft)
      if draft.persistent_draft_id.present?
        PersistentEntryDraft.where(id: draft.persistent_draft_id).delete_all
      end
      entry
    end
  end

  def stage_persistent_draft!(draft)
    record = draft.persist!
    draft.persistent_draft_id = record.id
    record
  end

  def render_save_failure(action)
    load_recent_people
    if action == :create
      render :new, status: :unprocessable_entity
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def load_recent_people
    @recent_people = RecentPeopleQuery.call
  end

  def load_draft_for_preview
    draft_id = params[:draft_id].presence || params.dig(:entry, :draft_id).presence
    load_draft_from_record(draft_id)
  end

  def load_draft_from_record(draft_id)
    return if draft_id.blank?

    record = PersistentEntryDraft.find_by(id: draft_id)
    return unless record

    EntryDraft.from_record(record)
  end

  def find_persistent_draft!
    record = PersistentEntryDraft.find_by(id: params[:draft_id]) if params[:draft_id].present?
    unless record
      redirect_to new_entry_path, alert: "No draft found."
      return nil
    end
    record
  end

  def assign_preview_variables(draft)
    @draft = draft
    @persistent_draft_id = draft.persistent_draft_id
    @persistent_draft = PersistentEntryDraft.find_by(id: draft.persistent_draft_id)
    @entry = Entry.find_by(id: draft.entry_id) if draft.entry_id.present?
    @relationship_diff = EntryRelationshipDiff.new(@entry, draft) if @entry
  end

  def initial_raw_date
    return Time.zone.today.strftime("%d %b %Y") if params[:occurred_on].blank?

    date = Date.iso8601(params[:occurred_on])
    date.strftime("%d %b %Y")
  rescue ArgumentError
    Time.zone.today.strftime("%d %b %Y")
  end

  # Optional Markdown body seed from Upcoming Calendar event titles (`body` query param).
  def initial_body_markdown
    return if params[:body].nil?

    params[:body].to_s
  end

  def preview_notice_for(draft)
    if draft.valid_for_save?
      "Draft saved. Everything looks good — click Save below when ready."
    elsif draft.unresolved_people.any?
      count = draft.unresolved_people.size
      "Draft saved. #{count} #{'person'.pluralize(count)} need#{'s' if count == 1} your attention below."
    else
      "Draft saved. Please fix the issues below before saving."
    end
  end
end
