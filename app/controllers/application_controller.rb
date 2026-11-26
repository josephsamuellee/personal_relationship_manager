class ApplicationController < ActionController::Base
  helper MarkdownHelper

  helper_method :entry_draft_in_session?, :current_theme, :most_recent_entry_draft

  private

  def current_theme
    Setting.current_theme
  end

  def entry_draft_in_session?
    PersistentEntryDraft.exists?
  end

  def most_recent_entry_draft
    PersistentEntryDraft.most_recent
  end
end
