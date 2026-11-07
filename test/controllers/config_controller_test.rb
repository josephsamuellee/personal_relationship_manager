require "test_helper"
require "minitest/mock"

class ConfigControllerTest < ActionDispatch::IntegrationTest
  setup do
    @person = Person.create!(name: "Andrew", slug: "andrew")
  end

  test "config page loads successfully" do
    get config_path

    assert_response :success
    assert_select "h1", text: "Config"
    assert_select "h2", text: "Appearance"
    assert_select "h2", text: "Favorite People"
    assert_select "h2", text: "Database"
  end

  test "favorite people settings are not editable from the config page" do
    Setting.assign_favorite_slot!(@person, 1)

    get config_path

    assert_response :success
    assert_select "h2", text: "Favorite People"
    assert_select "select", count: 0
    assert_select "input[name*='favorite']", count: 0
    assert_select ".placeholder em", text: /Person page/
    assert_match(/Favorite People homepage slots/, response.body)
  end

  test "config page displays database statistics" do
    create_entry!(title: "Today", occurred_on: Date.current, primary: @person)

    get config_path

    assert_response :success
    assert_select ".stats-table th", text: "Size"
    assert_match(/\d+\.\d{2} MB|Unavailable/, response.body)
    assert_select ".stats-table th", text: "Total entries"
    assert_select ".stats-table td", text: "1"
    assert_select ".stats-table th", text: "Created last 30 days"
  end

  test "config page displays current theme" do
    get config_path

    assert_response :success
    assert_select "html[data-theme=dark]"
    assert_match(/Theme:\s*Dark/, response.body)
  end

  test "application defaults to dark when no theme is configured" do
    assert_equal 0, Setting.count

    get homepage_path

    assert_response :success
    assert_select "html[data-theme=dark]"
  end

  test "changing theme to light persists and subsequent requests render light" do
    patch config_path, params: { theme: "light" }

    assert_redirected_to config_path
    assert_equal "light", Setting.current_theme

    follow_redirect!
    assert_response :success
    assert_select "html[data-theme=light]"
    assert_match(/Theme:\s*Light/, response.body)

    get homepage_path
    assert_select "html[data-theme=light]"
  end

  test "changing theme back to dark persists and subsequent requests render dark" do
    Setting.update_theme("light")

    patch config_path, params: { theme: "dark" }

    assert_redirected_to config_path
    assert_equal "dark", Setting.current_theme

    follow_redirect!
    assert_select "html[data-theme=dark]"
    assert_match(/Theme:\s*Dark/, response.body)
  end

  test "invalid theme values cannot produce an invalid application theme" do
    Setting.update_theme("light")

    patch config_path, params: { theme: "neon" }

    assert_equal "light", Setting.current_theme

    get config_path
    assert_select "html[data-theme=light]"
  end

  test "stored invalid theme falls back to dark on pages" do
    setting = Setting.create!(theme: "dark")
    setting.update_column(:theme, "purple")

    get config_path

    assert_response :success
    assert_select "html[data-theme=dark]"
  end

  test "database size failure does not crash config" do
    File.stub(:size, ->(*) { raise Errno::EIO, "io error" }) do
      get config_path
      assert_response :success
      assert_select "h1", text: "Config"
      assert_match(/Unavailable/, response.body)
    end
  end

  test "google calendar section shows setup steps when credentials are missing" do
    ENV.delete("GOOGLE_OAUTH_CLIENT_ID")
    ENV.delete("GOOGLE_OAUTH_CLIENT_SECRET")

    get config_path

    assert_response :success
    assert_select "h2", text: "Google Calendar"
    assert_match(/Not configured/, response.body)
    assert_select ".google-calendar-setup-steps"
    assert_match(/GOOGLE_OAUTH_CLIENT_ID/, response.body)
    assert_match(/GOOGLE_OAUTH_CLIENT_SECRET/, response.body)
    assert_match(%r{/google_calendar/oauth/callback}, response.body)
    assert_select "a[href=?]", "https://console.cloud.google.com/apis/credentials"
  end

  test "google calendar section shows disconnected without tokens" do
    ENV["GOOGLE_OAUTH_CLIENT_ID"] = "id"
    ENV["GOOGLE_OAUTH_CLIENT_SECRET"] = "secret"
    ENV["GOOGLE_CALENDAR_TOKEN_PATH"] = Rails.root.join("tmp", "missing_tokens.json.enc").to_s

    get config_path

    assert_response :success
    assert_select "h2", text: "Google Calendar"
    assert_match(/Disconnected/, response.body)
    assert_select "a", text: "Connect Google Calendar"
    assert_select "details.google-calendar-setup-details"
  ensure
    ENV.delete("GOOGLE_OAUTH_CLIENT_ID")
    ENV.delete("GOOGLE_OAUTH_CLIENT_SECRET")
    ENV.delete("GOOGLE_CALENDAR_TOKEN_PATH")
  end

  test "saves and clears google calendar allowlist" do
    Setting.update_google_calendar_allowlist([ "cal-a" ])

    patch config_path, params: {
      google_calendar_allowlist_form: "1",
      google_calendar_ids: [ "cal-a", "cal-c" ]
    }

    assert_redirected_to config_path
    assert_equal [ "cal-a", "cal-c" ], Setting.google_calendar_allowlist

    patch config_path, params: { google_calendar_allowlist_form: "1" }

    assert_redirected_to config_path
    assert_equal [], Setting.google_calendar_allowlist
  end
end
