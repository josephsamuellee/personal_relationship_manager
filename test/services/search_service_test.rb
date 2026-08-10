require "test_helper"

class SearchServiceTest < ActiveSupport::TestCase
  setup do
  @andrew = Person.create!(name: "Andrew", slug: "andrew")
    @andrew_hsiao = Person.create!(name: "Andrew Hsiao", slug: "andrew-hsiao")
    @andrew_wang = Person.create!(name: "Andrew Wang", slug: "andrew-wang")

    draft = EntryDraft.from_params(
      title: "Andrew dinner",
      raw_date: "09 Aug 2026",
      body_markdown: "Dinner with [[Andrew]] #dinner"
    )
    draft.person_selections = { "Andrew" => @andrew.id }
    draft.parse!
    EntrySaver.save!(draft)
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
end
