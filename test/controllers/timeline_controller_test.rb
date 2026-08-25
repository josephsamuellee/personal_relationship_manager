require "test_helper"

class TimelineControllerTest < ActionDispatch::IntegrationTest
  setup do
    @person = Person.create!(name: "Andrew", slug: "andrew")
  end

  test "show defaults to rendering the requested calendar year" do
    travel_to Time.zone.local(2026, 8, 18, 12, 0, 0) do
      get timeline_path(year: 2026)

      assert_response :success
      assert_select ".year-timeline-heading", text: /2026/
      assert_select ".year-timeline-row", count: 365
      assert_select ".year-timeline-iso", text: "W01-4", count: 1 # 2026-01-01 is Thursday
      assert_select ".year-timeline-cal", text: "01Jan", count: 1
      assert_select ".year-timeline-cal", text: "31Dec", count: 1
    end
  end

  test "leap year renders 366 rows including February 29" do
    create_entry!(title: "Leap", occurred_on: Date.new(2024, 2, 29), primary: @person)

    get timeline_path(year: 2024)

    assert_response :success
    assert_select ".year-timeline-row", count: 366
    assert_select ".year-timeline-cal", text: "29Feb", count: 1
  end

  test "dropdown years are derived from persisted entries" do
    create_entry!(title: "A", occurred_on: Date.new(2024, 1, 1), primary: @person)
    create_entry!(title: "B", occurred_on: Date.new(2026, 3, 1), primary: @person)

    get timeline_path(year: 2026)

    assert_response :success
    options = css_select(".year-timeline-year-select option").map { |opt| opt.text.strip }
    assert_equal %w[2024 2026], options
    assert_select ".year-timeline-year-select option[selected]", text: "2026"
  end

  test "selecting another year displays that year's dates and entries" do
    create_entry!(title: "Parents dinner", occurred_on: Date.new(2025, 8, 17), primary: @person)
    create_entry!(title: "Other", occurred_on: Date.new(2026, 1, 2), primary: @person)

    get timeline_path(year: 2025)

    assert_response :success
    assert_select ".year-timeline-heading", text: /2025/
    assert_select ".year-timeline-row", count: 365
    assert_select "a[href=?]", entry_path(Entry.find_by!(title: "Parents dinner")), text: "Parents dinner"
    assert_select "a", text: "Other", count: 0
  end

  test "previous and next arrows navigate between available database years and skip gaps" do
    create_entry!(title: "A", occurred_on: Date.new(2022, 1, 1), primary: @person)
    create_entry!(title: "B", occurred_on: Date.new(2024, 1, 1), primary: @person)
    create_entry!(title: "C", occurred_on: Date.new(2026, 1, 1), primary: @person)

    get timeline_path(year: 2026)

    assert_select ".year-timeline-nav-prev a[href=?]", timeline_path(year: 2024)
    assert_select ".year-timeline-nav-next .year-timeline-arrow.disabled", text: "→"

    get timeline_path(year: 2024)

    assert_select ".year-timeline-nav-prev a[href=?]", timeline_path(year: 2022)
    assert_select ".year-timeline-nav-next a[href=?]", timeline_path(year: 2026)

    get timeline_path(year: 2022)

    assert_select ".year-timeline-nav-prev .year-timeline-arrow.disabled", text: "←"
    assert_select ".year-timeline-nav-next a[href=?]", timeline_path(year: 2024)
  end

  test "days without entries still render and multiple entries share a date" do
    first = create_entry!(title: "Work teambonding", occurred_on: Date.new(2026, 8, 19), primary: @person)
    second = create_entry!(title: "Dinner with Jerry", occurred_on: Date.new(2026, 8, 19), primary: @person)

    get timeline_path(year: 2026)

    rows = css_select(".year-timeline-row")
    empty_row = rows.find { |row| row.at_css(".year-timeline-cal").text.strip == "18Aug" }
    filled_row = rows.find { |row| row.at_css(".year-timeline-cal").text.strip == "19Aug" }

    assert empty_row
    assert_equal "", empty_row.at_css(".year-timeline-entries").text.strip

    assert filled_row
    assert_select filled_row, "a[href=?]", entry_path(first), text: "Work teambonding"
    assert_select filled_row, "a[href=?]", entry_path(second), text: "Dinner with Jerry"
  end

  test "ISO week labels are correct around New Year boundaries" do
    create_entry!(title: "Boundary 2021", occurred_on: Date.new(2021, 1, 1), primary: @person)
    create_entry!(title: "Boundary 2025", occurred_on: Date.new(2025, 12, 29), primary: @person)

    get timeline_path(year: 2021)

    rows = css_select(".year-timeline-row")
    jan1 = rows.find { |row| row.at_css(".year-timeline-cal").text.strip == "01Jan" }
    assert jan1
    assert_equal "W53-5", jan1.at_css(".year-timeline-iso").text.strip

    get timeline_path(year: 2025)
    rows = css_select(".year-timeline-row")
    dec29 = rows.find { |row| row.at_css(".year-timeline-cal").text.strip == "29Dec" }
    assert dec29
    assert_equal "W01-1", dec29.at_css(".year-timeline-iso").text.strip
  end

  test "invalid year parameters redirect without crashing" do
    travel_to Time.zone.local(2026, 8, 18, 12, 0, 0) do
      get timeline_path(year: "foo")
      assert_redirected_to timeline_path(year: 2026)

      get timeline_path(year: "999999999")
      assert_redirected_to timeline_path(year: 2026)

      get timeline_path(year: "1900")
      assert_redirected_to timeline_path(year: 2026)
    end
  end

  test "rendering a year does not query entries once per day" do
    create_entry!(title: "A", occurred_on: Date.new(2026, 1, 1), primary: @person)
    create_entry!(title: "B", occurred_on: Date.new(2026, 6, 15), primary: @person)

    queries = []
    callback = lambda do |_name, _start, _finish, _id, payload|
      sql = payload[:sql]
      next if payload[:name] == "SCHEMA"
      next unless sql.match?(/FROM ["`]?entries["`]?/i)

      queries << sql
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      get timeline_path(year: 2026)
    end

    assert_response :success
    assert_operator queries.size, :<=, 2, "expected at most two entries queries, got #{queries.size}: #{queries}"
  end
end
