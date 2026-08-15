class ApplicationController < ActionController::Base
  helper MarkdownHelper

  helper_method :entry_draft_in_session?, :current_theme

  private

  def current_theme
    Setting.current_theme
  end

  def entry_draft_in_session?
    session[:entry_draft].present?
  end
end
