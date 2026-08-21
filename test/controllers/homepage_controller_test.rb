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

  test "favorite people section defaults to empty slots with see all people" do
    get homepage_path

    assert_response :success
    assert_select ".homepage > .homepage-section.favorite-people", count: 1
    assert_select ".favorite-people h2", text: "Favorite People"
    assert_select ".favorite-people-grid .favorite-people-slot", count: 4
    assert_select ".favorite-people-grid .favorite-people-slot a", count: 1
    assert_select ".favorite-people-see-all a[href=?]", people_path, text: "See all people"
  end

  test "homepage renders configured favorites linking to person pages" do
    andrew = Person.create!(name: "Andrew", slug: "andrew")
    carolyn = Person.create!(name: "Carolyn", slug: "carolyn")
    jerry = Person.create!(name: "Jerry", slug: "jerry")
    Setting.assign_favorite_slot!(andrew, 1)
    Setting.assign_favorite_slot!(carolyn, 2)
    Setting.assign_favorite_slot!(jerry, 3)

    get homepage_path

    assert_response :success
    slots = css_select(".favorite-people-grid .favorite-people-slot")
    assert_equal 4, slots.size
    assert_select slots[0], "a[href=?]", person_path(andrew), text: "Andrew"
    assert_select slots[1], "a[href=?]", person_path(carolyn), text: "Carolyn"
    assert_select slots[2], "a[href=?]", person_path(jerry), text: "Jerry"
    assert_select slots[3], "a[href=?]", people_path, text: "See all people"
  end

  test "see all people is always present even when favorites are empty" do
    get homepage_path

    assert_select "a[href=?]", people_path, text: "See all people"
  end

  test "stale favorite person references do not break the homepage" do
    andrew = Person.create!(name: "Andrew", slug: "andrew")
    carolyn = Person.create!(name: "Carolyn", slug: "carolyn")
    Setting.assign_favorite_slot!(andrew, 1)
    Setting.assign_favorite_slot!(carolyn, 2)
    andrew.destroy!

    get homepage_path

    assert_response :success
    assert_select ".favorite-people-grid .favorite-people-slot a[href=?]", person_path(carolyn), text: "Carolyn"
    assert_select ".favorite-people-grid a", text: "Andrew", count: 0
    assert_select "a[href=?]", people_path, text: "See all people"
  end

  test "landscape favorite people markup exposes four positions" do
    get homepage_path

    assert_select ".favorite-people-grid", count: 1
    assert_select ".favorite-people-grid .favorite-people-slot", count: 4
  end

  test "portrait-friendly favorite people markup lists see all people and omits empty person names" do
    andrew = Person.create!(name: "Andrew", slug: "andrew")
    Setting.assign_favorite_slot!(andrew, 2)

    get homepage_path

    assert_response :success
    links = css_select(".favorite-people-grid .favorite-people-slot a").map(&:text)
    assert_equal [ "Andrew", "See all people" ], links
    assert_select ".favorite-people-slot:empty", count: 2
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
