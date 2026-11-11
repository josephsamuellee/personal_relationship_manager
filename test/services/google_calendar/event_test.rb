require "test_helper"

class GoogleCalendar::EventTest < ActiveSupport::TestCase
  test "all-day event uses exclusive end date" do
    event = GoogleCalendar::Event.new(
      provider: "google",
      external_id: "allday1",
      calendar_id: "primary",
      title: "Holiday",
      starts_at: Date.new(2026, 11, 12),
      ends_at: Date.new(2026, 11, 13),
      all_day: true
    )

    assert_equal [ Date.new(2026, 11, 12) ], event.local_dates
  end

  test "multi-day all-day event spans inclusive dates" do
    event = GoogleCalendar::Event.new(
      provider: "google",
      external_id: "vac",
      calendar_id: "primary",
      title: "Family Vacation",
      starts_at: Date.new(2026, 11, 12),
      ends_at: Date.new(2026, 11, 15),
      all_day: true
    )

    assert_equal [
      Date.new(2026, 11, 12),
      Date.new(2026, 11, 13),
      Date.new(2026, 11, 14)
    ], event.local_dates
  end

  test "timed event crossing Taiwan Monday morning appears Sunday in Los Angeles" do
    # Monday 2026-11-09 08:00 Asia/Taipei == Sunday 2026-11-08 16:00 America/Los_Angeles
    start_utc = Time.find_zone!("Asia/Taipei").local(2026, 11, 9, 8, 0, 0)
    end_utc = start_utc + 1.hour

    event = GoogleCalendar::Event.new(
      provider: "google",
      external_id: "tw",
      calendar_id: "primary",
      title: "Taipei morning",
      starts_at: start_utc,
      ends_at: end_utc,
      all_day: false
    )

    assert_equal [ Date.new(2026, 11, 8) ], event.local_dates
  end

  test "timed event spanning local midnights appears on each overlapped date" do
    start_time = Time.zone.local(2026, 11, 12, 22, 0, 0)
    end_time = Time.zone.local(2026, 11, 14, 2, 0, 0)

    event = GoogleCalendar::Event.new(
      provider: "google",
      external_id: "span",
      calendar_id: "primary",
      title: "Overnight",
      starts_at: start_time,
      ends_at: end_time,
      all_day: false
    )

    assert_equal [
      Date.new(2026, 11, 12),
      Date.new(2026, 11, 13),
      Date.new(2026, 11, 14)
    ], event.local_dates
  end

  test "DST spring forward still assigns the correct local date" do
    # America/Los_Angeles 2026-03-08 02:00 skipped; event at 01:30 → 03:30 local
    start_time = Time.zone.local(2026, 3, 8, 1, 30, 0)
    end_time = Time.zone.local(2026, 3, 8, 3, 30, 0)

    event = GoogleCalendar::Event.new(
      provider: "google",
      external_id: "dst",
      calendar_id: "primary",
      title: "DST meeting",
      starts_at: start_time,
      ends_at: end_time,
      all_day: false
    )

    assert_equal [ Date.new(2026, 3, 8) ], event.local_dates
  end
end
