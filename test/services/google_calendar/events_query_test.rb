require "test_helper"
require "minitest/mock"

class GoogleCalendar::EventsQueryTest < ActiveSupport::TestCase
  class FakeClient
    attr_accessor :events_by_calendar

    def initialize(events_by_calendar = {})
      @events_by_calendar = events_by_calendar
    end

    def list_events(calendar_id:, time_min:, time_max:)
      Array(@events_by_calendar[calendar_id])
    end
  end

  ApiEvent = Struct.new(:id, :status, :summary, :start, :end, keyword_init: true)
  ApiTime = Struct.new(:date, :date_time, keyword_init: true)

  setup do
    travel_to Time.zone.local(2026, 11, 7, 12, 0, 0)
    ENV["GOOGLE_OAUTH_CLIENT_ID"] = "id"
    ENV["GOOGLE_OAUTH_CLIENT_SECRET"] = "secret"
    @token_path = Rails.root.join("tmp", "events_query_tokens_#{SecureRandom.hex(4)}.json.enc")
    ENV["GOOGLE_CALENDAR_TOKEN_PATH"] = @token_path.to_s
    GoogleCalendar::TokenStore.new(path: @token_path).store("prm", '{"refresh_token":"r"}')
  end

  teardown do
    FileUtils.rm_f(@token_path)
    ENV.delete("GOOGLE_OAUTH_CLIENT_ID")
    ENV.delete("GOOGLE_OAUTH_CLIENT_SECRET")
    ENV.delete("GOOGLE_CALENDAR_TOKEN_PATH")
  end

  test "empty allowlist returns empty events with empty_allowlist status" do
    Setting.update_google_calendar_allowlist([])
    GoogleCalendar::Oauth.stub(:status, :connected) do
      result = GoogleCalendar::EventsQuery.new(client: FakeClient.new).call
      assert_equal :empty_allowlist, result.status
      assert_equal [], result.events_by_date[Date.new(2026, 11, 12)]
    end
  end

  test "allowlist A and C only includes those calendars" do
    Setting.update_google_calendar_allowlist([ "cal-a", "cal-c" ])
    client = FakeClient.new(
      "cal-a" => [
        ApiEvent.new(
          id: "a1",
          status: "confirmed",
          summary: "From A",
          start: ApiTime.new(date_time: Time.zone.local(2026, 11, 12, 10, 0, 0)),
          end: ApiTime.new(date_time: Time.zone.local(2026, 11, 12, 11, 0, 0))
        )
      ],
      "cal-b" => [
        ApiEvent.new(
          id: "b1",
          status: "confirmed",
          summary: "From B",
          start: ApiTime.new(date_time: Time.zone.local(2026, 11, 12, 12, 0, 0)),
          end: ApiTime.new(date_time: Time.zone.local(2026, 11, 12, 13, 0, 0))
        )
      ],
      "cal-c" => [
        ApiEvent.new(
          id: "c1",
          status: "confirmed",
          summary: "From C",
          start: ApiTime.new(date_time: Time.zone.local(2026, 11, 12, 14, 0, 0)),
          end: ApiTime.new(date_time: Time.zone.local(2026, 11, 12, 15, 0, 0))
        )
      ]
    )

    GoogleCalendar::Oauth.stub(:status, :connected) do
      result = GoogleCalendar::EventsQuery.new(client: client).call
      titles = result.events_by_date[Date.new(2026, 11, 12)].map(&:title)
      assert_equal [ "From A", "From C" ], titles
      assert_equal :ok, result.status
    end
  end

  test "excludes cancelled events and expands recurring wednesday occurrences already expanded by API" do
    Setting.update_google_calendar_allowlist([ "cal-a" ])
    client = FakeClient.new(
      "cal-a" => [
        ApiEvent.new(
          id: "gone",
          status: "cancelled",
          summary: "Cancelled",
          start: ApiTime.new(date_time: Time.zone.local(2026, 11, 11, 10, 0, 0)),
          end: ApiTime.new(date_time: Time.zone.local(2026, 11, 11, 11, 0, 0))
        ),
        ApiEvent.new(
          id: "wed1",
          status: "confirmed",
          summary: "Weekly",
          start: ApiTime.new(date_time: Time.zone.local(2026, 11, 4, 9, 0, 0)),
          end: ApiTime.new(date_time: Time.zone.local(2026, 11, 4, 10, 0, 0))
        ),
        ApiEvent.new(
          id: "wed2",
          status: "confirmed",
          summary: "Weekly",
          start: ApiTime.new(date_time: Time.zone.local(2026, 11, 11, 9, 0, 0)),
          end: ApiTime.new(date_time: Time.zone.local(2026, 11, 11, 10, 0, 0))
        )
      ]
    )

    GoogleCalendar::Oauth.stub(:status, :connected) do
      result = GoogleCalendar::EventsQuery.new(client: client).call
      assert_equal [ "Weekly" ], result.events_by_date[Date.new(2026, 11, 4)].map(&:title)
      assert_equal [ "Weekly" ], result.events_by_date[Date.new(2026, 11, 11)].map(&:title)
      assert_equal [], result.events_by_date[Date.new(2026, 11, 4)].map(&:title) & [ "Cancelled" ]
    end
  end
end
