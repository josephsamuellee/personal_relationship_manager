require "googleauth"
require "googleauth/web_user_authorizer"
require "google/apis/calendar_v3"

module GoogleCalendar
  class Oauth
    SCOPES = [
      Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY
    ].freeze

    USER_ID = TokenStore::USER_ID

    class Error < StandardError; end
    class NotConfigured < Error; end
    class ReauthorizationRequired < Error; end

    def self.client_configured?
      ENV["GOOGLE_OAUTH_CLIENT_ID"].present? && ENV["GOOGLE_OAUTH_CLIENT_SECRET"].present?
    end

    def self.status
      return :not_configured unless client_configured?
      return :disconnected unless TokenStore.default.present?

      credentials = new.credentials
      return :reconnect_required unless credentials

      :connected
    rescue ReauthorizationRequired, Signet::AuthorizationError
      :reconnect_required
    end

    def initialize(token_store: TokenStore.default)
      @token_store = token_store
    end

    def authorization_url(request:, login_hint: nil)
      ensure_client_configured!
      authorizer(request).get_authorization_url(login_hint: login_hint, request: request)
    end

    def handle_callback(request:)
      ensure_client_configured!
      authorizer(request).handle_auth_callback(USER_ID, request)
    end

    def disconnect!
      @token_store.delete(USER_ID)
      @token_store.clear! if @token_store.load(USER_ID).blank?
    end

    def credentials
      ensure_client_configured!
      creds = authorizer_without_request.get_credentials(USER_ID)
      raise ReauthorizationRequired, "Google Calendar authorization missing" if creds.nil?

      if creds.respond_to?(:expires_within?) && creds.expires_within?(60)
        creds.fetch_access_token!
      end
      creds
    rescue Signet::AuthorizationError, Google::Auth::AuthorizationError => e
      raise ReauthorizationRequired, e.message
    end

    def redirect_uri_for(request)
      "#{request.base_url}/google_calendar/oauth/callback"
    end

    private

    def ensure_client_configured!
      raise NotConfigured, "GOOGLE_OAUTH_CLIENT_ID and GOOGLE_OAUTH_CLIENT_SECRET are required" unless self.class.client_configured?
    end

    def client_id
      Google::Auth::ClientId.new(
        ENV.fetch("GOOGLE_OAUTH_CLIENT_ID"),
        ENV.fetch("GOOGLE_OAUTH_CLIENT_SECRET")
      )
    end

    def authorizer(request)
      Google::Auth::WebUserAuthorizer.new(
        client_id,
        SCOPES,
        @token_store,
        redirect_uri_for(request)
      )
    end

    def authorizer_without_request
      # Redirect URI is unused when loading stored credentials.
      Google::Auth::UserAuthorizer.new(
        client_id,
        SCOPES,
        @token_store,
        "postmessage"
      )
    end
  end
end
