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
      unless client_configured?
        # #region agent log
        DebugLog.log("A", "oauth.rb:status", "oauth status branch", { status: "not_configured", clientIdPresent: ENV["GOOGLE_OAUTH_CLIENT_ID"].present?, clientSecretPresent: ENV["GOOGLE_OAUTH_CLIENT_SECRET"].present? })
        # #endregion
        return :not_configured
      end

      token_present = TokenStore.default.present?
      unless token_present
        # #region agent log
        DebugLog.log("C", "oauth.rb:status", "oauth status branch", { status: "disconnected", tokenPresent: false, tokenPath: TokenStore.default_path })
        # #endregion
        return :disconnected
      end

      credentials = new.credentials
      status = credentials ? :connected : :reconnect_required
      # #region agent log
      DebugLog.log("A", "oauth.rb:status", "oauth status after credentials", { status: status.to_s, tokenPresent: true, credentialsPresent: !credentials.nil? })
      # #endregion
      status
    rescue ReauthorizationRequired, Signet::AuthorizationError => e
      # #region agent log
      DebugLog.log("A", "oauth.rb:status", "oauth status reconnect_required", { status: "reconnect_required", errorClass: e.class.name, errorMessage: e.message.to_s[0, 200] })
      # #endregion
      :reconnect_required
    rescue StandardError => e
      # #region agent log
      DebugLog.log("A", "oauth.rb:status", "oauth status unexpected error", { errorClass: e.class.name, errorMessage: e.message.to_s[0, 300], backtrace0: e.backtrace&.first })
      # #endregion
      raise
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

      needs_refresh = creds.respond_to?(:expires_within?) && creds.expires_within?(60)
      # #region agent log
      DebugLog.log("A", "oauth.rb:credentials", "credentials loaded", { needsRefresh: needs_refresh, hasRefreshToken: creds.refresh_token.present?, expiresAt: (creds.expires_at rescue nil).to_s })
      # #endregion
      if needs_refresh
        creds.fetch_access_token!
        # #region agent log
        DebugLog.log("A", "oauth.rb:credentials", "access token refresh succeeded", {})
        # #endregion
      end
      creds
    rescue Signet::AuthorizationError, Google::Auth::AuthorizationError => e
      # #region agent log
      DebugLog.log("A", "oauth.rb:credentials", "credentials auth error", { errorClass: e.class.name, errorMessage: e.message.to_s[0, 300] })
      # #endregion
      raise ReauthorizationRequired, e.message
    rescue StandardError => e
      # #region agent log
      DebugLog.log("A", "oauth.rb:credentials", "credentials unexpected error", { errorClass: e.class.name, errorMessage: e.message.to_s[0, 300], backtrace0: e.backtrace&.first })
      # #endregion
      raise
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
