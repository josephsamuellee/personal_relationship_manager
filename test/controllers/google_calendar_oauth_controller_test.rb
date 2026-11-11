require "test_helper"
require "minitest/mock"

class GoogleCalendarOauthControllerTest < ActionDispatch::IntegrationTest
  setup do
    @token_path = Rails.root.join("tmp", "oauth_test_tokens_#{SecureRandom.hex(4)}.json.enc")
    ENV["GOOGLE_CALENDAR_TOKEN_PATH"] = @token_path.to_s
    ENV["GOOGLE_OAUTH_CLIENT_ID"] = "test-client-id"
    ENV["GOOGLE_OAUTH_CLIENT_SECRET"] = "test-client-secret"
  end

  teardown do
    FileUtils.rm_f(@token_path)
    ENV.delete("GOOGLE_CALENDAR_TOKEN_PATH")
    ENV.delete("GOOGLE_OAUTH_CLIENT_ID")
    ENV.delete("GOOGLE_OAUTH_CLIENT_SECRET")
  end

  test "connect redirects to Google when configured" do
    fake = Object.new
    def fake.authorization_url(request:)
      "https://accounts.google.com/o/oauth2/auth?client_id=test"
    end
    GoogleCalendar::Oauth.stub(:new, fake) do
      get google_calendar_oauth_connect_path
    end

    assert_response :redirect
    assert_match %r{\Ahttps://accounts\.google\.com/}, response.redirect_url
  end

  test "connect alerts when not configured" do
    ENV.delete("GOOGLE_OAUTH_CLIENT_ID")
    ENV.delete("GOOGLE_OAUTH_CLIENT_SECRET")

    get google_calendar_oauth_connect_path

    assert_redirected_to config_path
    assert_match(/not configured/i, flash[:alert])
  end

  test "disconnect clears tokens and does not expose them on config" do
    store = GoogleCalendar::TokenStore.new(path: @token_path)
    store.store("prm", '{"access_token":"super-secret","refresh_token":"also-secret"}')

    delete google_calendar_oauth_disconnect_path

    assert_redirected_to config_path
    assert_nil store.load("prm")

    get config_path
    assert_response :success
    refute_includes response.body, "super-secret"
    refute_includes response.body, "also-secret"
    assert_includes response.body, "Disconnected"
  end
end
