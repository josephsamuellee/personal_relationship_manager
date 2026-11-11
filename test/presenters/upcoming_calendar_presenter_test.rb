require "test_helper"

class UpcomingCalendarPresenterTest < ActiveSupport::TestCase
  test "renders two ISO weeks for 7 Nov 2026 with today outline metadata" do
    travel_to Time.zone.local(2026, 11, 7, 12, 0, 0) do
      presenter = UpcomingCalendarPresenter.new
      weeks = presenter.weeks

      assert_equal [ "W45", "W46" ], weeks.map(&:label)
      assert_equal Date.new(2026, 11, 2), weeks[0].dates.first
      assert_equal Date.new(2026, 11, 15), weeks[1].dates.last
      assert presenter.today?(Date.new(2026, 11, 7))
      assert_equal "07", presenter.day_label(Date.new(2026, 11, 7))
      assert_equal "02", presenter.day_label(Date.new(2026, 11, 2))
    end
  end

  test "ISO year boundary weeks" do
    travel_to Time.zone.local(2026, 12, 31, 12, 0, 0) do
      weeks = UpcomingCalendarPresenter.new.weeks
      assert_equal [ "W53", "W01" ], weeks.map(&:label)
      assert_equal 2026, weeks[0].iso_week_year
      assert_equal 2027, weeks[1].iso_week_year
    end
  end
end
