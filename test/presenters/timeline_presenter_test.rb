require "test_helper"

class TimelinePresenterTest < ActiveSupport::TestCase
  setup do
    @person = Person.create!(name: "Andrew", slug: "andrew")
  end

  test "available_years are distinct years from persisted entry dates only" do
    create_entry!(title: "A", occurred_on: Date.new(2024, 3, 1), primary: @person)
    create_entry!(title: "B", occurred_on: Date.new(2026, 1, 1), primary: @person)
    create_entry!(title: "C", occurred_on: Date.new(2024, 12, 31), primary: @person)
    create_entry!(title: "D", occurred_on: Date.new(2025, 6, 15), primary: @person)

    assert_equal [ 2024, 2025, 2026 ], TimelinePresenter.available_years
  end

  test "available_years is empty when there are no entries" do
    assert_equal [], TimelinePresenter.available_years
  end

  test "dates covers every calendar day of a normal year" do
    presenter = TimelinePresenter.new(year: 2025)

    assert_equal Date.new(2025, 1, 1), presenter.dates.first
    assert_equal Date.new(2025, 12, 31), presenter.dates.last
    assert_equal 365, presenter.dates.size
    assert_equal presenter.dates, presenter.dates.sort
    refute presenter.dates.include?(Date.new(2024, 2, 29))
  end

  test "dates includes February 29 in a leap year" do
    presenter = TimelinePresenter.new(year: 2024)

    assert_equal 366, presenter.dates.size
    assert_includes presenter.dates, Date.new(2024, 2, 29)
    assert_equal Date.new(2024, 1, 1), presenter.dates.first
    assert_equal Date.new(2024, 12, 31), presenter.dates.last
  end

  test "visible_dates hides empty days by default" do
    create_entry!(title: "Dinner", occurred_on: Date.new(2026, 8, 23), primary: @person)
    create_entry!(title: "Work", occurred_on: Date.new(2026, 8, 26), primary: @person)
    today = Date.new(2026, 8, 24)
    presenter = TimelinePresenter.new(year: 2026, today: today)

    assert_equal [
      Date.new(2026, 8, 23),
      Date.new(2026, 8, 24),
      Date.new(2026, 8, 26)
    ], presenter.visible_dates
  end

  test "visible_dates keeps today even when it has no entries" do
    create_entry!(title: "Dinner", occurred_on: Date.new(2026, 8, 23), primary: @person)
    today = Date.new(2026, 8, 24)
    presenter = TimelinePresenter.new(year: 2026, today: today)

    assert_includes presenter.visible_dates, today
    assert_equal [], presenter.entries_for(today)
  end

  test "visible_dates for a non-current empty year is empty until show_all" do
    today = Date.new(2026, 8, 24)
    filtered = TimelinePresenter.new(year: 2024, today: today)
    shown = TimelinePresenter.new(year: 2024, today: today, show_all: true)

    assert_equal [], filtered.visible_dates
    assert filtered.empty_filtered_state?
    assert_equal 366, shown.visible_dates.size
    refute shown.empty_filtered_state?
  end

  test "visible_dates with show_all returns every calendar day" do
    create_entry!(title: "Dinner", occurred_on: Date.new(2026, 8, 23), primary: @person)
    presenter = TimelinePresenter.new(year: 2026, today: Date.new(2026, 8, 24), show_all: true)

    assert_equal presenter.dates, presenter.visible_dates
    assert_equal 365, presenter.visible_dates.size
  end

  test "query_params includes show_all only when active" do
    hidden = TimelinePresenter.new(year: 2026, show_all: false)
    shown = TimelinePresenter.new(year: 2026, show_all: true)

    assert_equal({}, hidden.query_params)
    assert_equal({ show_all: 1 }, shown.query_params)
  end

  test "iso_week_day_label uses ISO week and Monday-based weekday" do
    presenter = TimelinePresenter.new(year: 2026)
    monday = Date.new(2026, 8, 17)

    assert monday.monday?
    assert_equal 1, monday.cwday
    assert_equal "W34-1", presenter.iso_week_day_label(monday)
    assert_equal "W34-7", presenter.iso_week_day_label(Date.new(2026, 8, 23))
  end

  test "iso_week_day_label follows ISO week-year near New Year" do
    presenter = TimelinePresenter.new(year: 2021)
    jan1 = Date.new(2021, 1, 1)

    assert_equal 53, jan1.cweek
    assert_equal 2020, jan1.cwyear
    assert_equal 5, jan1.cwday # Friday
    assert_equal "W53-5", presenter.iso_week_day_label(jan1)
  end

  test "iso_week_day_label can show W01 for late December" do
    presenter = TimelinePresenter.new(year: 2025)
    monday = Date.new(2025, 12, 29)

    assert_equal 1, monday.cweek
    assert_equal 2026, monday.cwyear
    assert_equal "W01-1", presenter.iso_week_day_label(monday)
  end

  test "iso_week_day_label supports ISO week 53" do
    presenter = TimelinePresenter.new(year: 2020)
    date = Date.new(2020, 12, 28)

    assert_equal 53, date.cweek
    assert_equal "W53-1", presenter.iso_week_day_label(date)
  end

  test "calendar_date_label uses compact DDMMM format" do
    presenter = TimelinePresenter.new(year: 2026)

    assert_equal "01Jan", presenter.calendar_date_label(Date.new(2026, 1, 1))
    assert_equal "17Aug", presenter.calendar_date_label(Date.new(2026, 8, 17))
    assert_equal "31Dec", presenter.calendar_date_label(Date.new(2026, 12, 31))
  end

  test "entries_by_date groups year entries in one ordered collection" do
    create_entry!(title: "Zebra", occurred_on: Date.new(2026, 8, 19), primary: @person)
    create_entry!(title: "Alpha", occurred_on: Date.new(2026, 8, 19), primary: @person)
    create_entry!(title: "Other year", occurred_on: Date.new(2025, 8, 19), primary: @person)
    create_entry!(title: "Solo", occurred_on: Date.new(2026, 1, 2), primary: @person)

    presenter = TimelinePresenter.new(year: 2026)
    grouped = presenter.entries_by_date

    assert_equal [ "Alpha", "Zebra" ], grouped[Date.new(2026, 8, 19)].map(&:title)
    assert_equal [ "Solo" ], grouped[Date.new(2026, 1, 2)].map(&:title)
    assert_nil grouped[Date.new(2025, 8, 19)]
    assert_equal [], presenter.entries_for(Date.new(2026, 1, 1))
  end

  test "previous and next year skip missing database years" do
    create_entry!(title: "A", occurred_on: Date.new(2022, 1, 1), primary: @person)
    create_entry!(title: "B", occurred_on: Date.new(2024, 1, 1), primary: @person)
    create_entry!(title: "C", occurred_on: Date.new(2026, 1, 1), primary: @person)

    presenter = TimelinePresenter.new(year: 2026)

    assert_equal 2024, presenter.previous_year
    assert_nil presenter.next_year

    mid = TimelinePresenter.new(year: 2024)
    assert_equal 2022, mid.previous_year
    assert_equal 2026, mid.next_year

    first = TimelinePresenter.new(year: 2022)
    assert_nil first.previous_year
    assert_equal 2024, first.next_year
  end

  test "parse_year falls back for invalid years and allows empty in-range years" do
    create_entry!(title: "A", occurred_on: Date.new(2024, 1, 1), primary: @person)
    today = Date.new(2026, 8, 18)

    assert_equal 2026, TimelinePresenter.parse_year("2026", today: today)
    assert_equal 2024, TimelinePresenter.parse_year("2024", today: today)
    assert_equal 1900, TimelinePresenter.parse_year("1900", today: today)
    assert_equal 2026, TimelinePresenter.parse_year("foo", today: today)
    assert_equal 2026, TimelinePresenter.parse_year("999999999", today: today)
    assert_equal 2026, TimelinePresenter.parse_year("-1", today: today)
  end

  test "parse_year allows current year even without entries for that year" do
    create_entry!(title: "A", occurred_on: Date.new(2024, 1, 1), primary: @person)
    today = Date.new(2026, 8, 18)

    assert_equal 2026, TimelinePresenter.parse_year("2026", today: today)
    assert_equal [ 2024 ], TimelinePresenter.available_years
  end

  test "entries_by_date issues a single entries query for the year" do
    create_entry!(title: "A", occurred_on: Date.new(2026, 1, 1), primary: @person)
    create_entry!(title: "B", occurred_on: Date.new(2026, 6, 1), primary: @person)
    create_entry!(title: "C", occurred_on: Date.new(2026, 12, 31), primary: @person)

    presenter = TimelinePresenter.new(year: 2026)
    queries = []
    callback = lambda do |_name, _start, _finish, _id, payload|
      sql = payload[:sql]
      next if payload[:name] == "SCHEMA"
      next unless sql.match?(/["`]?entries["`]?/i)

      queries << sql
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      presenter.entries_by_date
      presenter.visible_dates.each { |date| presenter.entries_for(date) }
    end

    assert_equal 1, queries.size, "expected one entries query, got: #{queries}"
  end
end
