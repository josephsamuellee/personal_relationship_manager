require "test_helper"

class SettingGoogleCalendarAllowlistTest < ActiveSupport::TestCase
  test "defaults to empty allowlist" do
    assert_equal [], Setting.google_calendar_allowlist
  end

  test "stores and returns unique calendar ids" do
    Setting.update_google_calendar_allowlist([ "cal-a", "cal-c", "cal-a", "" ])

    assert_equal [ "cal-a", "cal-c" ], Setting.google_calendar_allowlist
  end

  test "clears allowlist when empty array saved" do
    Setting.update_google_calendar_allowlist([ "cal-a" ])
    Setting.update_google_calendar_allowlist([])

    assert_equal [], Setting.google_calendar_allowlist
  end
end
