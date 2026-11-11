require "test_helper"

class GoogleCalendar::EventAggregatorTest < ActiveSupport::TestCase
  setup do
    travel_to Time.zone.local(2026, 11, 7, 12, 0, 0)
    @range = GoogleCalendar::WeekRange.for(Time.zone.today)
  end

  test "dedupes only by reliable identity across calendars" do
    shared = GoogleCalendar::Event.new(
      provider: "google",
      external_id: "same-id",
      calendar_id: "cal-a",
      title: "Shared",
      starts_at: Time.zone.local(2026, 11, 12, 10, 0, 0),
      ends_at: Time.zone.local(2026, 11, 12, 11, 0, 0),
      all_day: false
    )
    duplicate = GoogleCalendar::Event.new(
      provider: "google",
      external_id: "same-id",
      calendar_id: "cal-c",
      title: "Shared",
      starts_at: Time.zone.local(2026, 11, 12, 10, 0, 0),
      ends_at: Time.zone.local(2026, 11, 12, 11, 0, 0),
      all_day: false
    )

    grouped = GoogleCalendar::EventAggregator.group_by_date([ shared, duplicate ], range: @range)

    assert_equal 1, grouped[Date.new(2026, 11, 12)].size
  end

  test "does not dedupe distinct events that share title and date" do
    a = GoogleCalendar::Event.new(
      provider: "google",
      external_id: "id-a",
      calendar_id: "cal-a",
      title: "Dinner",
      starts_at: Time.zone.local(2026, 11, 12, 18, 0, 0),
      ends_at: Time.zone.local(2026, 11, 12, 19, 0, 0),
      all_day: false
    )
    b = GoogleCalendar::Event.new(
      provider: "google",
      external_id: "id-b",
      calendar_id: "cal-c",
      title: "Dinner",
      starts_at: Time.zone.local(2026, 11, 12, 18, 0, 0),
      ends_at: Time.zone.local(2026, 11, 12, 19, 0, 0),
      all_day: false
    )

    grouped = GoogleCalendar::EventAggregator.group_by_date([ a, b ], range: @range)

    assert_equal 2, grouped[Date.new(2026, 11, 12)].size
  end

  test "places multi-day event on each overlapped date in range" do
    event = GoogleCalendar::Event.new(
      provider: "google",
      external_id: "vac",
      calendar_id: "primary",
      title: "Family Vacation",
      starts_at: Date.new(2026, 11, 12),
      ends_at: Date.new(2026, 11, 15),
      all_day: true
    )

    grouped = GoogleCalendar::EventAggregator.group_by_date([ event ], range: @range)

    assert_equal [ "Family Vacation" ], grouped[Date.new(2026, 11, 12)].map(&:title)
    assert_equal [ "Family Vacation" ], grouped[Date.new(2026, 11, 13)].map(&:title)
    assert_equal [ "Family Vacation" ], grouped[Date.new(2026, 11, 14)].map(&:title)
  end
end
