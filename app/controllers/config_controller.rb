class ConfigController < ApplicationController
  def show
    @theme = Setting.current_theme
    @statistics = ServerStatistics.new
    @google_status = GoogleCalendar::Oauth.status
    @google_allowlist = Setting.google_calendar_allowlist
    @google_calendars = load_google_calendars
  end

  def update
    if params.key?(:theme)
      Setting.update_theme(params[:theme])
    end

    if params.key?(:google_calendar_ids) || params[:google_calendar_allowlist_form].present?
      ids = Array(params[:google_calendar_ids])
      Setting.update_google_calendar_allowlist(ids)
      redirect_to config_path, notice: "Google Calendar selection saved."
      return
    end

    redirect_to config_path
  end

  private

  def load_google_calendars
    return [] unless @google_status == :connected

    GoogleCalendar::Client.new.list_calendars
  rescue GoogleCalendar::Oauth::ReauthorizationRequired
    @google_status = :reconnect_required
    []
  rescue StandardError => e
    Rails.logger.warn("[GoogleCalendar] calendar list failed: #{e.class}")
    []
  end
end
