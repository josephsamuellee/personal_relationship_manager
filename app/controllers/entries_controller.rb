class EntriesController < ApplicationController
  before_action :set_entry, only: [:show, :edit, :update, :create_preview_update]

  def new
    @draft = if session[:entry_draft]
      EntryDraft.from_session(session[:entry_draft])
    else
      EntryDraft.new(raw_date: Time.zone.today.strftime("%d %b %Y"))
    end
  end

  def create
    draft = load_draft_from_session
    if draft&.valid_for_save?
      entry = EntrySaver.save!(draft)
      session.delete(:entry_draft)
      redirect_to entry_path(entry), notice: "Entry saved."
    elsif draft
      redirect_to preview_entries_path, alert: "Could not save entry. Please resolve the issues below."
    else
      redirect_to new_entry_path, alert: "No draft found. Please create and preview an entry first."
    end
  end

  def show_preview
    draft = load_draft_from_session
    unless draft
      redirect_to new_entry_path, alert: "No draft to preview. Start a new entry."
      return
    end

    assign_preview_variables(draft)
    render :preview
  end

  def create_preview
    draft = EntryDraft.from_params(entry_params)
    session[:entry_draft] = draft.to_session
    redirect_to preview_entries_path, notice: preview_notice_for(draft)
  end

  def create_preview_update
    draft = EntryDraft.from_params(entry_params.merge(entry_id: @entry.id))
    session[:entry_draft] = draft.to_session
    redirect_to preview_entries_path, notice: preview_notice_for(draft)
  end

  def show
  end

  def edit
    if session[:entry_draft] && session[:entry_draft]["entry_id"].to_i == @entry.id
      @draft = EntryDraft.from_session(session[:entry_draft])
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
    draft = load_draft_from_session
    if draft&.valid_for_save? && draft.entry_id.to_i == @entry.id
      entry = EntrySaver.save!(draft)
      session.delete(:entry_draft)
      redirect_to entry_path(entry), notice: "Entry updated."
    elsif draft
      redirect_to preview_entries_path, alert: "Could not update entry. Please resolve the issues below."
    else
      redirect_to edit_entry_path(@entry), alert: "No draft found. Please preview your changes first."
    end
  end

  def resolve_person
    draft_data = session[:entry_draft] || {}
    draft_data["person_selections"] ||= {}
    draft_data["person_selections"][params[:name]] = params[:person_id]
    session[:entry_draft] = draft_data

    draft = EntryDraft.from_session(draft_data)
    session[:entry_draft] = draft.to_session
    redirect_to preview_entries_path, notice: "Selected #{params[:name]}."
  end

  def create_person
    person = Person.create!(name: params[:name])
    draft_data = session[:entry_draft] || {}
    draft_data["person_selections"] ||= {}
    draft_data["person_selections"][params[:name]] = person.id.to_s
    session[:entry_draft] = draft_data

    draft = EntryDraft.from_session(draft_data)
    session[:entry_draft] = draft.to_session
    redirect_to preview_entries_path, notice: "Created and linked #{person.name}."
  end

  def replace_person_name
    draft_data = session[:entry_draft]
    unless draft_data
      redirect_to new_entry_path, alert: "No draft found."
      return
    end

    old_name = params[:name]
    new_name = params[:replacement]
    draft = EntryDraft.from_session(draft_data)
    draft.replace_person_link!(old_name, new_name)
    session[:entry_draft] = draft.to_session

    # #region agent log
    File.open("/Users/josephlee/Documents/personal_relationship_manager/.cursor/debug-ff4759.log", "a") do |f|
      f.puts({ sessionId: "ff4759", runId: "post-fix", hypothesisId: "B", location: "entries_controller.rb:replace_person_name", message: "replaced person link in draft", data: { old_name: old_name, new_name: new_name, body_markdown: draft.body_markdown, unresolved_remaining: draft.unresolved_people.size }, timestamp: (Time.now.to_f * 1000).to_i }.to_json)
    end
    # #endregion

    redirect_to preview_entries_path, notice: "Changed all \"#{old_name}\" to \"#{new_name}\"."
  end

  def drafts
    @draft = load_draft_from_session
  end

  def discard_draft
    session.delete(:entry_draft)
    redirect_to new_entry_path, notice: "Draft discarded."
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

  def assign_preview_variables(draft)
    @draft = draft
    @entry = Entry.find_by(id: draft.entry_id) if draft.entry_id.present?
    @relationship_diff = EntryRelationshipDiff.new(@entry, draft) if @entry
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
