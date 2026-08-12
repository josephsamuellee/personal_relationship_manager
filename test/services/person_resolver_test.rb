require "test_helper"

class PersonResolverTest < ActiveSupport::TestCase
  setup do
    @andrew = Person.create!(name: "Andrew", slug: "andrew")
    @andrew_hsiao = Person.create!(name: "Andrew Hsiao", slug: "andrew-hsiao")
    @andrew_wang = Person.create!(name: "Andrew Wang", slug: "andrew-wang")
  end

  test "exact match" do
    result = PersonResolver.resolve("Andrew")
    assert result.exact?
    assert_equal @andrew, result.people.first
  end

  test "ambiguous match when multiple prefix matches" do
    Person.where(name: "Andrew").delete_all
    result = PersonResolver.resolve("Andrew")
    assert result.ambiguous?
    assert_operator result.people.size, :>=, 2
  end

  test "unknown person" do
    result = PersonResolver.resolve("Nobody")
    assert result.unknown?
  end

  test "suggest returns prefix matches using first three characters" do
    foobar = Person.create!(name: "Foobar", slug: "foobar")
    Person.create!(name: "Foodie", slug: "foodie")

    suggestions = PersonResolver.suggest("foobra")
    assert_includes suggestions.map(&:name), "Foobar"
    assert_includes suggestions.map(&:name), "Foodie"
    assert_not_includes suggestions.map(&:name), "foobra"
  end

  test "suggest returns empty for blank name" do
    assert_empty PersonResolver.suggest("")
    assert_empty PersonResolver.suggest(nil)
  end
end
