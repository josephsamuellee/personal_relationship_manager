require "test_helper"

class SearchServiceTest < ActiveSupport::TestCase
  setup do
    @andrew = Person.create!(name: "Andrew", slug: "andrew")
    @andrew_hsiao = Person.create!(name: "Andrew Hsiao", slug: "andrew-hsiao")
    @andrew_wang = Person.create!(name: "Andrew Wang", slug: "andrew-wang")
    @sarah = Person.create!(name: "Sarah T", slug: "sarah-t")
    @bret = Person.create!(name: "Bret T", slug: "bret-t")

    create_entry!(
      title: "Andrew dinner",
      occurred_on: Date.new(2026, 8, 9),
      primary: @andrew,
      body: "Dinner with [[Andrew]] #dinner"
    )
  end

  test "returns at most three people results" do
    results = SearchService.new("andrew").results
    assert results[:people].size <= 3
    assert results[:people].all? { |p| p.name.downcase.include?("andrew") }
  end

  test "returns timeline results for valid date" do
    results = SearchService.new("09 Aug 2026").results
    assert results[:timeline].size <= 3
  end

  test "returns entry results" do
    results = SearchService.new("dinner").results
    assert results[:entries].size <= 3
  end

  test "limits global entry search to three newest matching entries" do
    create_trip_entries

    results = SearchService.new("trip").results
    titles = results[:entries].map(&:title)

    assert_equal 3, titles.size
    assert_equal ["Beach Trip", "Trip Planning", "Joshua Tree Trip"], titles
    assert results[:more_entries]
  end

  test "does not show more entries when three or fewer match" do
    results = SearchService.new("dinner").results

    assert_equal 1, results[:entries].size
    assert_not results[:more_entries]
  end

  test "full entry search returns all matching records ordered by occurred_on desc" do
    create_trip_entries

    entries = SearchService.new("trip").all_entries.to_a

    assert_equal 5, entries.size
    assert_equal(
      ["Beach Trip", "Trip Planning", "Joshua Tree Trip", "Christmas Trip", "Summer Trip"],
      entries.map(&:title)
    )
  end

  test "full entry search uses the same title tag and body matching as the preview" do
    title_match = create_entry!(
      title: "Canyon trip",
      occurred_on: Date.new(2026, 5, 1),
      primary: @andrew
    )
    tag_match = create_entry!(
      title: "Tagged outing",
      occurred_on: Date.new(2026, 4, 1),
      primary: @andrew,
      body: "A walk with [[Andrew]]",
      tags: ["trip"]
    )
    body_match = create_entry!(
      title: "Planning notes",
      occurred_on: Date.new(2026, 3, 1),
      primary: @sarah,
      body: "Discussed the trip itinerary with [[Sarah T]]"
    )
    create_entry!(
      title: "Unrelated lunch",
      occurred_on: Date.new(2026, 2, 1),
      primary: @bret,
      body: "Lunch with [[Bret T]] #lunch"
    )

    preview_titles = SearchService.new("trip").results[:entries].map(&:title)
    full_titles = SearchService.new("trip").all_entries.map(&:title)

    assert_equal [title_match.title, tag_match.title, body_match.title], full_titles
    assert_equal full_titles.first(preview_titles.size), preview_titles
    assert_not_includes full_titles, "Unrelated lunch"
    assert_not_includes preview_titles, "Unrelated lunch"
  end

  test "full entry search orders by occurred_on rather than created_at" do
    older = create_entry!(
      title: "Older trip",
      occurred_on: Date.new(2025, 1, 1),
      primary: @andrew
    )
    newer = create_entry!(
      title: "Newer trip",
      occurred_on: Date.new(2026, 1, 1),
      primary: @sarah
    )
    older.update_column(:created_at, 1.hour.from_now)
    newer.update_column(:created_at, 1.day.ago)

    titles = SearchService.new("trip").all_entries.map(&:title)

    assert_equal ["Newer trip", "Older trip"], titles
  end

  test "people search results remain unchanged by entry search expansion" do
    create_trip_entries

    people = SearchService.new("andrew").results[:people]

    assert_equal 3, people.size
    assert_equal ["Andrew", "Andrew Hsiao", "Andrew Wang"], people.map(&:name)
  end

  private

  def create_trip_entries
    create_entry!(title: "Beach Trip", occurred_on: Date.new(2026, 8, 12), primary: @andrew, people: [@andrew, @sarah])
    create_entry!(title: "Trip Planning", occurred_on: Date.new(2026, 7, 3), primary: @andrew)
    create_entry!(title: "Joshua Tree Trip", occurred_on: Date.new(2026, 5, 15), primary: @sarah, people: [@sarah, @bret])
    create_entry!(title: "Christmas Trip", occurred_on: Date.new(2025, 12, 20), primary: @andrew, people: [@andrew, @bret])
    create_entry!(title: "Summer Trip", occurred_on: Date.new(2025, 6, 10), primary: @andrew)
  end
end
