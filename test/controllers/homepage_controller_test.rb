require "test_helper"

class HomepageControllerTest < ActionDispatch::IntegrationTest
  test "homepage contains a config link at the bottom of page content" do
    get homepage_path

    assert_response :success
    assert_select ".floating-nav-top a", text: "Config", count: 0
    assert_select ".homepage-config-link a[href=?]", config_path, text: "Config"

    html = Nokogiri::HTML(response.body)
    last_homepage_content = html.at_css(".homepage > *:last-child")
    assert_equal "homepage-config-link", last_homepage_content["class"]
  end

  test "recent timeline renders week numbers, today, and a 7/8 landscape split" do
    person = Person.create!(name: "Andrew", slug: "andrew")
    travel_to Time.zone.local(2026, 8, 18, 12, 0, 0) do
      monday_entry = create_entry!(
        title: "Family dinner",
        occurred_on: Date.new(2026, 8, 17),
        primary: person
      )
      today_entry = create_entry!(
        title: "Airport trip",
        occurred_on: Date.new(2026, 8, 18),
        primary: person
      )

      get homepage_path

      assert_response :success

      groups = css_select(".recent-timeline-group")
      assert_equal 2, groups.size
      assert_equal 7, groups[0].css(".recent-timeline-row").size
      assert_equal 8, groups[1].css(".recent-timeline-row").size

      rows = css_select(".recent-timeline-row")
      assert_equal 15, rows.size
      assert_includes rows.last["class"], "today"
      assert_select ".recent-timeline-row.today", count: 1
      assert_includes groups[1].css(".recent-timeline-row").last["class"], "today"

      week_labels = rows.map { |row| row.at_css(".recent-timeline-week").text.strip }
      assert_equal [ "", "", "", "", "", "", "W33" ], week_labels.first(7)
      assert_equal [ "", "", "", "", "", "", "W34", "W34" ], week_labels.last(8)

      weekday_letters = rows.map { |row| row.at_css(".recent-timeline-day").text.strip }
      assert_equal %w[T W T F S S M T W T F S S M T], weekday_letters

      assert_select ".recent-timeline-row.today .recent-timeline-week", text: "W34"
      assert_select "a[href=?]", entry_path(monday_entry), text: "Family dinner"
      assert_select ".recent-timeline-row.today a[href=?]", entry_path(today_entry), text: "Airport trip"
    end
  end
end
