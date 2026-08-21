require "test_helper"

class HomepagePresenterTest < ActiveSupport::TestCase
  test "recent_timeline spans matching weekday two weeks back through today" do
    today = Date.new(2026, 8, 9) # Sunday
    presenter = HomepagePresenter.new(today: today)
    dates = presenter.recent_timeline_dates

    assert_equal Date.new(2026, 7, 26), dates.first
    assert_equal today, dates.last
    assert_equal 15, dates.size
    assert_equal dates, dates.sort
  end

  test "landscape groups split the same fifteen dates into oldest seven and newest eight" do
    today = Date.new(2026, 8, 18)
    presenter = HomepagePresenter.new(today: today)
    dates = presenter.recent_timeline_dates

    assert_equal dates.first(7), presenter.recent_timeline_older_dates
    assert_equal dates.drop(7), presenter.recent_timeline_newer_dates
    assert_equal 7, presenter.recent_timeline_older_dates.size
    assert_equal 8, presenter.recent_timeline_newer_dates.size
    assert_equal dates, presenter.recent_timeline_older_dates + presenter.recent_timeline_newer_dates
    assert_equal dates.first, presenter.recent_timeline_older_dates.first
    assert_equal today, presenter.recent_timeline_newer_dates.last
  end

  test "week_label shows the ISO week number on Mondays" do
    today = Date.new(2026, 8, 18) # Tuesday
    presenter = HomepagePresenter.new(today: today)
    monday = Date.new(2026, 8, 10)

    assert monday.monday?
    refute presenter.today?(monday)
    assert_equal "W33", presenter.week_label(monday)
  end

  test "week_label is blank for ordinary non-Monday dates" do
    today = Date.new(2026, 8, 18) # Tuesday
    presenter = HomepagePresenter.new(today: today)
    wednesday = Date.new(2026, 8, 12)

    refute wednesday.monday?
    refute presenter.today?(wednesday)
    assert_nil presenter.week_label(wednesday)
  end

  test "week_label shows today's ISO week number regardless of weekday" do
    today = Date.new(2026, 8, 18) # Tuesday
    presenter = HomepagePresenter.new(today: today)

    refute today.monday?
    assert presenter.today?(today)
    assert_equal "W34", presenter.week_label(today)
  end

  test "week_label does not duplicate when today is Monday" do
    today = Date.new(2026, 8, 17) # Monday
    presenter = HomepagePresenter.new(today: today)

    assert today.monday?
    assert presenter.today?(today)
    assert_equal "W34", presenter.week_label(today)
  end

  test "week_label zero-pads single-digit ISO week numbers" do
    monday = Date.commercial(2026, 9, 1)
    today = monday + 2
    presenter = HomepagePresenter.new(today: today)

    assert_equal Date.new(2026, 2, 23), monday
    assert_equal "W09", presenter.week_label(monday)
    assert_equal "W09", presenter.week_label(today)
    assert_nil presenter.week_label(monday + 1)
  end

  test "week_label follows ISO week year across the December/January boundary" do
    # 2021-01-01 is Friday; ISO week 53 of 2020, not calendar-year W01.
    today = Date.new(2021, 1, 1)
    presenter = HomepagePresenter.new(today: today)
    monday = Date.new(2020, 12, 28)

    assert_equal 53, today.cweek
    assert_equal 2020, today.cwyear
    refute today.monday?
    assert_equal "W53", presenter.week_label(today)

    assert monday.monday?
    assert_equal "W53", presenter.week_label(monday)
    assert_nil presenter.week_label(Date.new(2020, 12, 29))
  end

  test "week_label can show W01 for a late-December Monday" do
    # 2025-12-29 is Monday and belongs to ISO week 1 of 2026.
    today = Date.new(2025, 12, 31)
    presenter = HomepagePresenter.new(today: today)
    monday = Date.new(2025, 12, 29)

    assert monday.monday?
    assert_equal 1, monday.cweek
    assert_equal 2026, monday.cwyear
    assert_equal "W01", presenter.week_label(monday)
    assert_equal "W01", presenter.week_label(today)
  end

  test "historical window uses calendar month arithmetic" do
    today = Date.new(2026, 8, 9)
    presenter = HomepagePresenter.new(today: today)
    window = presenter.historical_window

    assert_equal Date.new(2026, 5, 9), window[:anchor]
    assert_equal Date.new(2026, 5, 2), window[:start_date]
    assert_equal Date.new(2026, 5, 16), window[:end_date]
  end

  test "favorite_people returns only configured people in slot order" do
    andrew = Person.create!(name: "Andrew", slug: "andrew")
    carolyn = Person.create!(name: "Carolyn", slug: "carolyn")
    Person.create!(name: "Jerry", slug: "jerry")
    Setting.assign_favorite_slot!(carolyn, 2)
    Setting.assign_favorite_slot!(andrew, 1)

    presenter = HomepagePresenter.new

    assert_equal [ andrew, carolyn, nil ], presenter.favorite_people
  end

  test "favorite_people defaults to three empty slots" do
    presenter = HomepagePresenter.new

    assert_equal [ nil, nil, nil ], presenter.favorite_people
  end
end
