require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    @andrew = Person.create!(name: "Andrew", slug: "andrew")
    @sarah = Person.create!(name: "Sarah T", slug: "sarah-t")
    @bret = Person.create!(name: "Bret T", slug: "bret-t")
  end

  test "global search still limits entries to three and links see all with the query" do
    create_trip_entries

    get search_path, params: { q: "trip" }

    assert_response :success
    assert_select "h2", text: "Entries"
    assert_select "a", text: "Beach Trip"
    assert_select "a", text: "Trip Planning"
    assert_select "a", text: "Joshua Tree Trip"
    assert_select "a", text: "Christmas Trip", count: 0
    assert_select "a", text: "Summer Trip", count: 0
    assert_select "a[href=?]", search_entries_path(q: "trip"), text: "See all entries"
  end

  test "see all entries is omitted when three or fewer entries match" do
    create_entry!(title: "Beach Trip", occurred_on: Date.new(2026, 8, 12), primary: @andrew)

    get search_path, params: { q: "trip" }

    assert_response :success
    assert_select "a", text: "See all entries", count: 0
  end

  test "full entry search renders all matching entries as a table" do
    entries = create_trip_entries

    get search_entries_path, params: { q: "trip" }

    assert_response :success
    assert_select "h1", text: 'Entries matching "trip"'
    assert_select "table.search-entries-table tbody tr", count: 5
    assert_select "a[href=?]", entry_path(entries.fetch(:beach)), text: "Beach Trip"
    assert_select "a[href=?]", entry_path(entries.fetch(:planning)), text: "Trip Planning"
    assert_select "a[href=?]", entry_path(entries.fetch(:joshua)), text: "Joshua Tree Trip"
    assert_select "a[href=?]", entry_path(entries.fetch(:christmas)), text: "Christmas Trip"
    assert_select "a[href=?]", entry_path(entries.fetch(:summer)), text: "Summer Trip"

    titles = css_select("table.search-entries-table tbody tr td:first-child a").map(&:text)
    assert_equal(
      ["Beach Trip", "Trip Planning", "Joshua Tree Trip", "Christmas Trip", "Summer Trip"],
      titles
    )
    dates = css_select("table.search-entries-table tbody tr td:nth-child(2)").map { |td| td.text.strip }
    assert_equal ["2026-08-12", "2026-07-03", "2026-05-15", "2025-12-20", "2025-06-10"], dates
  end

  test "people column lists primary person first then referenced people without duplicates" do
    entry = create_entry!(
      title: "Group Trip",
      occurred_on: Date.new(2026, 8, 1),
      primary: @andrew,
      people: [@andrew, @sarah, @bret]
    )

    get search_entries_path, params: { q: "trip" }

    assert_response :success
    row = css_select("table.search-entries-table tbody tr").first
    people_cell = row.css("td")[2]
    names = people_cell.css("a").map { |link| [link.text, link["href"]] }

    assert_equal(
      [
        ["Andrew", person_path(@andrew)],
        ["Sarah T", person_path(@sarah)],
        ["Bret T", person_path(@bret)]
      ],
      names
    )
    assert_equal "Andrew, Sarah T, Bret T", people_cell.text.gsub(/\s+/, " ").strip
    assert_equal 1, names.count { |name, _| name == "Andrew" }
    assert_select "a[href=?]", entry_path(entry), text: "Group Trip"
  end

  test "empty full entry search does not render a table" do
    get search_entries_path, params: { q: "andrew" }

    assert_response :success
    assert_select "p", text: 'No entries found matching "andrew".'
    assert_select "table.search-entries-table", count: 0
  end

  test "people and timeline sections are unchanged on the global search page" do
    create_trip_entries
    Person.create!(name: "Andrew Hsiao", slug: "andrew-hsiao")
    Person.create!(name: "Andrew Wang", slug: "andrew-wang")

    get search_path, params: { q: "andrew" }

    assert_response :success
    assert_select "h2", text: "People"
    assert_select "h2", text: "Timeline / Date"
    assert_select "a", text: /See all people/, count: 0
    assert_select "a", text: /See all entries/, count: 0
  end

  private

  def create_trip_entries
    {
      beach: create_entry!(title: "Beach Trip", occurred_on: Date.new(2026, 8, 12), primary: @andrew, people: [@andrew, @sarah]),
      planning: create_entry!(title: "Trip Planning", occurred_on: Date.new(2026, 7, 3), primary: @andrew),
      joshua: create_entry!(title: "Joshua Tree Trip", occurred_on: Date.new(2026, 5, 15), primary: @sarah, people: [@sarah, @bret]),
      christmas: create_entry!(title: "Christmas Trip", occurred_on: Date.new(2025, 12, 20), primary: @andrew, people: [@andrew, @bret]),
      summer: create_entry!(title: "Summer Trip", occurred_on: Date.new(2025, 6, 10), primary: @andrew)
    }
  end
end
