class EntriesController < ApplicationController
  before_action :set_entry, only: [:show, :edit, :update, :preview_update]

  def new
    @draft = EntryDraft.new(raw_date: Time.zone.today.strftime("%d %b %Y"))
  end

  def create
    draft = load_draft_from_session
    if draft&.valid_for_save?
      entry = EntrySaver.save!(draft)
      session.delete(:entry_draft)
      redirect_to entry_path(entry), notice: "Entry saved."
    else
      redirect_to new_entry_path, alert: "Could not save entry. Please preview again."
    end
  end

  def preview
    draft = EntryDraft.from_params(entry_params)
    session[:entry_draft] = draft.to_session
    @draft = draft
    @entry = Entry.find_by(id: draft.entry_id) if draft.entry_id.present?
    @relationship_diff = EntryRelationshipDiff.new(@entry, draft) if @entry
    render :preview
  end

  def show
  end

  def edit
    @draft = EntryDraft.new(
      title: @entry.title,
      raw_date: @entry.occurred_on.strftime("%d %b %Y"),
      body_markdown: @entry.body_markdown,
      entry_id: @entry.id
    )
    @draft.parse!
  end

  def preview_update
    draft = EntryDraft.from_params(entry_params.merge(entry_id: @entry.id))
    session[:entry_draft] = draft.to_session
    @draft = draft
    @relationship_diff = EntryRelationshipDiff.new(@entry, draft)
    render :preview
  end

  def update
    draft = load_draft_from_session
    if draft&.valid_for_save? && draft.entry_id.to_i == @entry.id
      entry = EntrySaver.save!(draft)
      session.delete(:entry_draft)
      redirect_to entry_path(entry), notice: "Entry updated."
    else
      redirect_to edit_entry_path(@entry), alert: "Could not update entry. Please preview again."
    end
  end

  def resolve_person
    draft_data = session[:entry_draft] || {}
    draft_data["person_selections"] ||= {}
    draft_data["person_selections"][params[:name]] = params[:person_id]
    session[:entry_draft] = draft_data

    draft = EntryDraft.from_session(draft_data)
    session[:entry_draft] = draft.to_session
    @draft = draft
    @entry = Entry.find_by(id: draft.entry_id)
    render :preview
  end

  def create_person
    person = Person.create!(name: params[:name])
    draft_data = session[:entry_draft] || {}
    draft_data["person_selections"] ||= {}
    draft_data["person_selections"][params[:name]] = person.id.to_s
    session[:entry_draft] = draft_data

    draft = EntryDraft.from_session(draft_data)
    session[:entry_draft] = draft.to_session
    @draft = draft
    @entry = Entry.find_by(id: draft.entry_id)
    render :preview
  end

  private

  def set_entry
    @entry = Entry.includes(:primary_person, :people, :tags).find(params[:id])
  end

  def entry_params
    params.require(:entry).permit(:title, :raw_date, :occurred_on, :body_markdown, :entry_id, person_selections: {})
  end

  def load_draft_from_session
    return unless session[:entry_draft]

    EntryDraft.from_session(session[:entry_draft])
  end
end
