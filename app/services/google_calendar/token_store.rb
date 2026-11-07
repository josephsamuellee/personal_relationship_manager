require "googleauth/token_store"

module GoogleCalendar
  # Encrypted on-disk token store. Tokens never pass through Config HTML.
  class TokenStore < Google::Auth::TokenStore
    USER_ID = "prm".freeze

    def self.default
      new(path: default_path)
    end

    def self.default_path
      ENV.fetch("GOOGLE_CALENDAR_TOKEN_PATH") do
        Rails.root.join("storage", "google_calendar_tokens.json.enc").to_s
      end
    end

    def initialize(path:)
      @path = path.to_s
    end

    def load(id)
      data = read_all
      data[id.to_s]
    end

    def store(id, token)
      data = read_all
      data[id.to_s] = token
      write_all(data)
    end

    def delete(id)
      data = read_all
      data.delete(id.to_s)
      write_all(data)
    end

    def clear!
      FileUtils.rm_f(@path)
    end

    def present?
      load(USER_ID).present?
    end

    private

    def read_all
      return {} unless File.exist?(@path)

      raw = File.binread(@path)
      JSON.parse(encryptor.decrypt_and_verify(raw))
    rescue ActiveSupport::MessageEncryptor::InvalidMessage, JSON::ParserError, ArgumentError
      {}
    end

    def write_all(data)
      FileUtils.mkdir_p(File.dirname(@path))
      payload = encryptor.encrypt_and_sign(JSON.generate(data))
      File.binwrite(@path, payload)
      File.chmod(0o600, @path) if File.exist?(@path)
    end

    def encryptor
      key = ActiveSupport::KeyGenerator.new(secret_key_base).generate_key("google-calendar-tokens", 32)
      ActiveSupport::MessageEncryptor.new(key)
    end

    def secret_key_base
      Rails.application.secret_key_base.presence ||
        ENV["SECRET_KEY_BASE"].presence ||
        raise("SECRET_KEY_BASE required to encrypt Google Calendar tokens")
    end
  end
end
