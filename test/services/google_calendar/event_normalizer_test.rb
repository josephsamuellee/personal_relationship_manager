require "test_helper"

class GoogleCalendar::EventNormalizerTest < ActiveSupport::TestCase
  test "skips cancelled events" do
    item = {
      "id" => "c1",
      "status" => "cancelled",
      "summary" => "Gone",
      "start" => { "dateTime" => "2026-11-12T10:00:00-08:00" },
      "end" => { "dateTime" => "2026-11-12T11:00:00-08:00" }
    }

    assert_nil GoogleCalendar::EventNormalizer.from_api(item, calendar_id: "cal-a")
  end

  test "normalizes timed event title and times" do
    item = {
      "id" => "t1",
      "status" => "confirmed",
      "summary" => "Dinner with Jerry",
      "start" => { "dateTime" => "2026-11-12T18:00:00-08:00" },
      "end" => { "dateTime" => "2026-11-12T20:00:00-08:00" }
    }

    event = GoogleCalendar::EventNormalizer.from_api(item, calendar_id: "cal-a")

    assert_equal "Dinner with Jerry", event.title
    assert_equal "t1", event.external_id
    assert_equal "cal-a", event.calendar_id
    assert_equal [ Date.new(2026, 11, 12) ], event.local_dates
    refute event.all_day?
  end

  test "normalizes all-day exclusive end" do
    item = {
      "id" => "a1",
      "summary" => "Holiday",
      "start" => { "date" => "2026-11-12" },
      "end" => { "date" => "2026-11-13" }
    }

    event = GoogleCalendar::EventNormalizer.from_api(item, calendar_id: "cal-a")

    assert event.all_day?
    assert_equal [ Date.new(2026, 11, 12) ], event.local_dates
  end

  test "normalizes all-day dates when Google API returns Date objects" do
    item = {
      "id" => "a2",
      "summary" => "Holiday",
      "start" => { "date" => Date.new(2026, 11, 12) },
      "end" => { "date" => Date.new(2026, 11, 13) }
    }

    event = GoogleCalendar::EventNormalizer.from_api(item, calendar_id: "cal-a")

    assert event.all_day?
    assert_equal [ Date.new(2026, 11, 12) ], event.local_dates
  end
end
