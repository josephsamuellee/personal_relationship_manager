class ApplicationController < ActionController::Base
  helper MarkdownHelper

  helper_method :entry_draft_in_session?

  private

  def entry_draft_in_session?
    session[:entry_draft].present?
  end
end
