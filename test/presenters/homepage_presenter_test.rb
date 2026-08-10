require "test_helper"

class HomepagePresenterTest < ActiveSupport::TestCase
  test "recent_timeline spans matching weekday two weeks back through today" do
    today = Date.new(2026, 8, 9) # Sunday
    presenter = HomepagePresenter.new(today: today)
    dates = presenter.recent_timeline_dates

    assert_equal Date.new(2026, 7, 26), dates.first
    assert_equal today, dates.last
    assert_equal 15, dates.size
  end

  test "historical window uses calendar month arithmetic" do
    today = Date.new(2026, 8, 9)
    presenter = HomepagePresenter.new(today: today)
    window = presenter.historical_window

    assert_equal Date.new(2026, 5, 9), window[:anchor]
    assert_equal Date.new(2026, 5, 2), window[:start_date]
    assert_equal Date.new(2026, 5, 16), window[:end_date]
  end
end
