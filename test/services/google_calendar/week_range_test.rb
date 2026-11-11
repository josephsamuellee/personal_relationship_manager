require "test_helper"

class GoogleCalendar::WeekRangeTest < ActiveSupport::TestCase
  test "Saturday 7 Nov 2026 shows W45 then W46" do
    travel_to Time.zone.local(2026, 11, 7, 12, 0, 0) do
      range = GoogleCalendar::WeekRange.for(Time.zone.today)
      weeks = range.weeks

      assert_equal 2, weeks.size
      assert_equal "W45", weeks[0].label
      assert_equal Date.new(2026, 11, 2), weeks[0].dates.first
      assert_equal Date.new(2026, 11, 8), weeks[0].dates.last
      assert_equal "W46", weeks[1].label
      assert_equal Date.new(2026, 11, 9), weeks[1].dates.first
      assert_equal Date.new(2026, 11, 15), weeks[1].dates.last
      assert_equal Date.new(2026, 11, 2), range.start_date
      assert_equal Date.new(2026, 11, 15), range.end_date
    end
  end

  test "31 Dec 2026 shows 2026-W53 then 2027-W01" do
    travel_to Time.zone.local(2026, 12, 31, 12, 0, 0) do
      weeks = GoogleCalendar::WeekRange.for(Time.zone.today).weeks

      assert_equal 2026, weeks[0].iso_week_year
      assert_equal 53, weeks[0].iso_week
      assert_equal "W53", weeks[0].label
      assert_equal Date.new(2026, 12, 28), weeks[0].dates.first
      assert_equal Date.new(2027, 1, 3), weeks[0].dates.last

      assert_equal 2027, weeks[1].iso_week_year
      assert_equal 1, weeks[1].iso_week
      assert_equal "W01", weeks[1].label
      assert_equal Date.new(2027, 1, 4), weeks[1].dates.first
      assert_equal Date.new(2027, 1, 10), weeks[1].dates.last
    end
  end

  test "Sunday still includes current ISO week as first row" do
    travel_to Time.zone.local(2026, 11, 8, 12, 0, 0) do
      weeks = GoogleCalendar::WeekRange.for(Time.zone.today).weeks

      assert_equal "W45", weeks[0].label
      assert_includes weeks[0].dates, Date.new(2026, 11, 8)
      assert_equal "W46", weeks[1].label
    end
  end
end
