require "test_helper"
require "minitest/mock"

class UpcomingCalendarEventsControllerTest < ActionDispatch::IntegrationTest
  test "returns json without secrets on success" do
    result = GoogleCalendar::EventsQuery::Result.new(
      status: :ok,
      events_by_date: {
        Date.new(2026, 11, 12) => [
          GoogleCalendar::Event.new(
            provider: "google",
            external_id: "e1",
            calendar_id: "cal-a",
            title: "Dinner with Jerry",
            starts_at: Time.zone.local(2026, 11, 12, 18, 0, 0),
            ends_at: Time.zone.local(2026, 11, 12, 20, 0, 0),
            all_day: false
          )
        ]
      },
      message: nil
    )

    GoogleCalendar::EventsQuery.stub(:new, ->(*) { Object.new.tap { |o| o.define_singleton_method(:call) { result } } }) do
      get upcoming_calendar_events_path
    end

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "ok", body["status"]
    assert_equal "Dinner with Jerry", body["events_by_date"]["2026-11-12"].first["title"]
    refute_includes response.body, "access_token"
    refute_includes response.body, "refresh_token"
    refute_includes response.body, "CLIENT_SECRET"
  end

  test "returns reconnect_required without exposing credentials" do
    result = GoogleCalendar::EventsQuery::Result.new(
      status: :reconnect_required,
      events_by_date: {},
      message: "Reconnect Google Calendar in Config."
    )

    GoogleCalendar::EventsQuery.stub(:new, ->(*) { Object.new.tap { |o| o.define_singleton_method(:call) { result } } }) do
      get upcoming_calendar_events_path
    end

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "reconnect_required", body["status"]
    refute_includes response.body, "secret"
  end

  test "returns error status on failure payload" do
    result = GoogleCalendar::EventsQuery::Result.new(
      status: :error,
      events_by_date: {},
      message: "Google Calendar is temporarily unavailable."
    )

    GoogleCalendar::EventsQuery.stub(:new, ->(*) { Object.new.tap { |o| o.define_singleton_method(:call) { result } } }) do
      get upcoming_calendar_events_path
    end

    assert_response :success
    assert_equal "error", JSON.parse(response.body)["status"]
  end
end
