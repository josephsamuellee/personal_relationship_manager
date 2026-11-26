class EntryDraftsController < ApplicationController
  before_action :load_recent_people, only: [ :edit ]

  def create
    if draft_params[:client_create_id].present?
      existing = PersistentEntryDraft.find_by(client_create_id: draft_params[:client_create_id])
      if existing
        render json: draft_json(existing), status: :ok
        return
      end
    end

    record = PersistentEntryDraft.find_or_initialize_for_create(
      client_create_id: draft_params[:client_create_id],
      entry_id: draft_params[:entry_id]
    )
    was_new = record.new_record?
    assign_autosave_fields!(record)
    record.client_create_id ||= draft_params[:client_create_id].presence

    begin
      record.save!
    rescue ActiveRecord::RecordNotUnique
      record = PersistentEntryDraft.find_by!(client_create_id: draft_params[:client_create_id])
      render json: draft_json(record), status: :ok
      return
    end

    render json: draft_json(record), status: was_new ? :created : :ok
  end

  def update
    record = PersistentEntryDraft.find_by(id: params[:id])
    unless record
      render json: { error: "gone" }, status: :gone
      return
    end

    unless draft_params.key?(:lock_version)
      render json: { error: "lock_version_required" }, status: :unprocessable_entity
      return
    end

    record.apply_expected_lock_version!(draft_params[:lock_version])
    assign_autosave_fields!(record)

    begin
      record.save!
    rescue ActiveRecord::StaleObjectError
      record.reload
      render json: record.conflict_payload(edit_url: edit_entry_draft_path(record)), status: :conflict
      return
    end

    render json: draft_json(record)
  end

  def edit
    record = PersistentEntryDraft.find(params[:id])
    @draft = EntryDraft.from_record(record)
    @persistent_draft = record

    if record.entry_id.present?
      @entry = Entry.includes(:primary_person, :people, :tags).find(record.entry_id)
      @entry_changed_warning = record.entry_changed?
      render "entries/edit"
    else
      @orphaned_edit_warning = record.orphaned_edit?
      render "entries/new"
    end
  end

  private

  def assign_autosave_fields!(record)
    attrs = draft_params
    record.title = attrs[:title] if attrs.key?(:title)
    record.raw_date = attrs[:raw_date] if attrs.key?(:raw_date)
    record.body_markdown = attrs[:body_markdown].to_s if attrs.key?(:body_markdown)
    if attrs.key?(:entry_id) && record.entry_id.blank? && attrs[:entry_id].present?
      record.entry_id = attrs[:entry_id]
    end
    record.content_updated_at = Time.current
  end

  def draft_params
    params.require(:entry_draft).permit(
      :title, :raw_date, :body_markdown, :entry_id, :lock_version, :client_create_id
    )
  end

  def draft_json(record)
    {
      id: record.id,
      content_updated_at: record.content_updated_at&.iso8601(3),
      lock_version: record.lock_version,
      client_create_id: record.client_create_id,
      edit_url: edit_entry_draft_path(record)
    }
  end

  def load_recent_people
    @recent_people = RecentPeopleQuery.call
  end
end
