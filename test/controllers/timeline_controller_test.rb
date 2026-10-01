require "test_helper"

class TimelineControllerTest < ActionDispatch::IntegrationTest
  setup do
    @person = Person.create!(name: "Andrew", slug: "andrew")
  end

  test "show defaults to filtered dates for the requested calendar year" do
    travel_to Time.zone.local(2026, 8, 24, 12, 0, 0) do
      create_entry!(title: "Parents dinner", occurred_on: Date.new(2026, 8, 23), primary: @person)
      create_entry!(title: "Work teambonding", occurred_on: Date.new(2026, 8, 26), primary: @person)

      get timeline_path(year: 2026)

      assert_response :success
      assert_select ".year-timeline-heading", text: /2026/
      assert_select ".year-timeline-sticky", count: 1
      assert_select ".year-timeline-sticky .year-timeline-header", count: 1
      assert_select ".year-timeline-sticky .year-timeline-controls", count: 1
      assert_select ".year-timeline-table .year-timeline-sticky", count: 0
      assert_select ".year-timeline-row", count: 3
      assert_select ".year-timeline-cal", text: "23Aug", count: 1
      assert_select ".year-timeline-cal", text: "24Aug", count: 1
      assert_select ".year-timeline-cal", text: "25Aug", count: 0
      assert_select ".year-timeline-cal", text: "26Aug", count: 1
      assert_select "a", text: "Show all days"
      assert_select "a", text: "Jump to today"
    end
  end

  test "empty dates are hidden by default while entry dates remain visible" do
    travel_to Time.zone.local(2026, 8, 24, 12, 0, 0) do
      create_entry!(title: "Parents dinner", occurred_on: Date.new(2026, 8, 23), primary: @person)

      get timeline_path(year: 2026)

      rows = css_select(".year-timeline-row")
      labels = rows.map { |row| row.at_css(".year-timeline-cal").text.strip }
      assert_equal %w[23Aug 24Aug], labels
    end
  end

  test "today remains visible with literal today marker before entry titles" do
    travel_to Time.zone.local(2026, 8, 24, 12, 0, 0) do
      first = create_entry!(title: "Parents dinner", occurred_on: Date.new(2026, 8, 24), primary: @person)
      second = create_entry!(title: "Work teambonding", occurred_on: Date.new(2026, 8, 24), primary: @person)

      get timeline_path(year: 2026)

      assert_select "#today", count: 1
      assert_select ".year-timeline-row.today", count: 1
      today_row = css_select("#today").first
      entries_text = today_row.at_css(".year-timeline-entries").text.gsub(/\s+/, " ").strip
      assert_match(/\A\(today\) Parents dinner/, entries_text)
      assert_includes entries_text, "Work teambonding"
      assert_select "#today .year-timeline-today-marker", text: "(today)"
      assert_select "#today a[href=?]", entry_path(first), text: "Parents dinner"
      assert_select "#today a[href=?]", entry_path(second), text: "Work teambonding"
    end
  end

  test "today without entries still renders the today marker and anchor" do
    travel_to Time.zone.local(2026, 8, 24, 12, 0, 0) do
      get timeline_path(year: 2026)

      assert_select "#today", count: 1
      assert_select "#today .year-timeline-cal", text: "24Aug"
      assert_select "#today .year-timeline-today-marker", text: "(today)"
      assert_equal "(today)", css_select("#today .year-timeline-entries").text.strip
    end
  end

  test "show all days renders every calendar date including empties" do
    travel_to Time.zone.local(2026, 8, 24, 12, 0, 0) do
      create_entry!(title: "Parents dinner", occurred_on: Date.new(2026, 8, 23), primary: @person)

      get timeline_path(year: 2026, show_all: 1)

      assert_response :success
      assert_select ".year-timeline-row", count: 365
      assert_select ".year-timeline-cal", text: "01Jan", count: 1
      assert_select ".year-timeline-cal", text: "25Aug", count: 1
      assert_select ".year-timeline-cal", text: "31Dec", count: 1
      assert_select "a[href=?]", timeline_path(year: 2026), text: "Hide empty days"
    end
  end

  test "leap year show all renders 366 rows including February 29" do
    create_entry!(title: "Leap", occurred_on: Date.new(2024, 2, 29), primary: @person)

    get timeline_path(year: 2024, show_all: 1)

    assert_response :success
    assert_select ".year-timeline-row", count: 366
    assert_select ".year-timeline-cal", text: "29Feb", count: 1
  end

  test "hide empty days returns to filtered behavior" do
    travel_to Time.zone.local(2026, 8, 24, 12, 0, 0) do
      create_entry!(title: "Parents dinner", occurred_on: Date.new(2026, 8, 23), primary: @person)

      get timeline_path(year: 2026, show_all: 1)
      assert_select "a[href=?]", timeline_path(year: 2026), text: "Hide empty days"

      get timeline_path(year: 2026)
      assert_select ".year-timeline-row", count: 2
      assert_select "a[href=?]", timeline_path(year: 2026, show_all: 1), text: "Show all days"
    end
  end

  test "show_all survives previous and next year navigation" do
    create_entry!(title: "A", occurred_on: Date.new(2024, 1, 1), primary: @person)
    create_entry!(title: "B", occurred_on: Date.new(2026, 1, 1), primary: @person)

    get timeline_path(year: 2026, show_all: 1)

    assert_select ".year-timeline-nav-prev a[href=?]", timeline_path(year: 2024, show_all: 1)
    assert_select ".year-timeline-year-select option[value=?]", timeline_path(year: 2024, show_all: 1)
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

  test "selecting another year displays that year's entries without empty days by default" do
    create_entry!(title: "Parents dinner", occurred_on: Date.new(2025, 8, 17), primary: @person)
    create_entry!(title: "Other", occurred_on: Date.new(2026, 1, 2), primary: @person)

    get timeline_path(year: 2025)

    assert_response :success
    assert_select ".year-timeline-heading", text: /2025/
    assert_select ".year-timeline-row", count: 1
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

  test "multiple entries share a date and empty days stay hidden by default" do
    travel_to Time.zone.local(2026, 8, 24, 12, 0, 0) do
      first = create_entry!(title: "Work teambonding", occurred_on: Date.new(2026, 8, 19), primary: @person)
      second = create_entry!(title: "Dinner with Jerry", occurred_on: Date.new(2026, 8, 19), primary: @person)

      get timeline_path(year: 2026)

      rows = css_select(".year-timeline-row")
      labels = rows.map { |row| row.at_css(".year-timeline-cal").text.strip }
      assert_equal %w[19Aug 24Aug], labels

      filled_row = rows.find { |row| row.at_css(".year-timeline-cal").text.strip == "19Aug" }
      assert_select filled_row, "a[href=?]", entry_path(first), text: "Work teambonding"
      assert_select filled_row, "a[href=?]", entry_path(second), text: "Dinner with Jerry"
    end
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

  test "jump to today targets today on the current year" do
    travel_to Time.zone.local(2026, 8, 24, 12, 0, 0) do
      get timeline_path(year: 2026)

      assert_select "a[href=?]", timeline_path(year: 2026, anchor: "today"), text: "Jump to today"
      assert_select "#today", count: 1
    end
  end

  test "jump to today from another year navigates to current year and preserves show_all" do
    travel_to Time.zone.local(2026, 8, 24, 12, 0, 0) do
      create_entry!(title: "Old", occurred_on: Date.new(2024, 1, 1), primary: @person)

      get timeline_path(year: 2024, show_all: 1)

      assert_select "a[href=?]",
                    timeline_path(year: 2026, show_all: 1, anchor: "today"),
                    text: "Jump to today"
    end
  end

  test "empty non-current year shows empty state until show all days" do
    travel_to Time.zone.local(2026, 8, 24, 12, 0, 0) do
      get timeline_path(year: 2025)

      assert_response :success
      assert_select ".year-timeline-empty", text: "No entries for this year."
      assert_select ".year-timeline-row", count: 0
      assert_select "a[href=?]", timeline_path(year: 2025, show_all: 1), text: "Show all days"

      get timeline_path(year: 2025, show_all: 1)

      assert_select ".year-timeline-empty", count: 0
      assert_select ".year-timeline-row", count: 365
    end
  end

  test "calendar date labels link to new entry for that date in filtered view" do
    travel_to Time.zone.local(2026, 9, 28, 12, 0, 0) do
      populated = create_entry!(title: "Parents dinner", occurred_on: Date.new(2026, 9, 27), primary: @person)

      get timeline_path(year: 2026)

      assert_response :success
      assert_select ".year-timeline-cal-link[href=?]", new_entry_path(occurred_on: "2026-09-27"), text: "27Sep"
      assert_select ".year-timeline-cal-link[href=?]", new_entry_path(occurred_on: "2026-09-28"), text: "28Sep"
      assert_select "a[href=?]", entry_path(populated), text: "Parents dinner"
      assert_select ".floating-actions a[href=?]", new_entry_path, text: "Add Entry"
      assert_select ".floating-actions a[href=?]", new_entry_path(occurred_on: "2026-09-28"), count: 0
    end
  end

  test "calendar date labels link to new entry for empty days in show all" do
    travel_to Time.zone.local(2026, 9, 28, 12, 0, 0) do
      populated = create_entry!(title: "Parents dinner", occurred_on: Date.new(2026, 9, 27), primary: @person)

      get timeline_path(year: 2026, show_all: 1)

      assert_response :success
      assert_select ".year-timeline-cal-link[href=?]", new_entry_path(occurred_on: "2026-01-01"), text: "01Jan"
      assert_select ".year-timeline-cal-link[href=?]", new_entry_path(occurred_on: "2026-09-01"), text: "01Sep"
      assert_select ".year-timeline-cal-link[href=?]", new_entry_path(occurred_on: "2026-09-27"), text: "27Sep"
      assert_select ".year-timeline-cal-link[href=?]", new_entry_path(occurred_on: "2026-09-28"), text: "28Sep"
      assert_select "a[href=?]", entry_path(populated), text: "Parents dinner"
      assert_select ".floating-actions a[href=?]", new_entry_path, text: "Add Entry"
    end
  end

  test "invalid year parameters redirect without crashing" do
    travel_to Time.zone.local(2026, 8, 18, 12, 0, 0) do
      get timeline_path(year: "foo")
      assert_redirected_to timeline_path(year: 2026)

      get timeline_path(year: "999999999")
      assert_redirected_to timeline_path(year: 2026)

      get timeline_path(year: "-1")
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
