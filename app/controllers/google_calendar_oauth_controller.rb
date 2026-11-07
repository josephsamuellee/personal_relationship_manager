class GoogleCalendarOauthController < ApplicationController
  def connect
    oauth = GoogleCalendar::Oauth.new
    redirect_to oauth.authorization_url(request: request), allow_other_host: true
  rescue GoogleCalendar::Oauth::NotConfigured
    redirect_to config_path, alert: "Google OAuth client ID and secret are not configured."
  end

  def callback
    GoogleCalendar::Oauth.new.handle_callback(request: request)
    redirect_to config_path, notice: "Google Calendar connected. Select calendars below."
  rescue GoogleCalendar::Oauth::NotConfigured
    redirect_to config_path, alert: "Google OAuth client ID and secret are not configured."
  rescue Signet::AuthorizationError, Google::Auth::AuthorizationError => e
    Rails.logger.warn("[GoogleCalendar] OAuth callback failed: #{e.class}")
    redirect_to config_path, alert: "Google Calendar authorization failed. Try connecting again."
  end

  def disconnect
    GoogleCalendar::Oauth.new.disconnect!
    redirect_to config_path, notice: "Google Calendar disconnected."
  end
end
