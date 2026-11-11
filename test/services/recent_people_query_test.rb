require "test_helper"

class RecentPeopleQueryTest < ActiveSupport::TestCase
  setup do
    @ada = Person.create!(name: "Ada Lovelace", slug: "ada-lovelace")
    @grace = Person.create!(name: "Grace Hopper", slug: "grace-hopper")
    @alan = Person.create!(name: "Alan Turing", slug: "alan-turing")
    @never = Person.create!(name: "Never Referenced", slug: "never-referenced")
  end

  test "returns empty when no people are associated with saved entries" do
    assert_equal [], RecentPeopleQuery.call
  end

  test "excludes people never associated with a saved entry" do
    create_entry!(title: "Ada only", occurred_on: Date.new(2024, 1, 1), primary: @ada)

    names = RecentPeopleQuery.call.map(&:name)
    assert_includes names, "Ada Lovelace"
    refute_includes names, "Never Referenced"
  end

  test "ranks by most recent associated entry chronology" do
    create_entry!(title: "Old Ada", occurred_on: Date.new(2020, 1, 1), primary: @ada)
    create_entry!(title: "Mid Grace", occurred_on: Date.new(2022, 6, 1), primary: @grace)
    create_entry!(title: "New Alan", occurred_on: Date.new(2024, 3, 1), primary: @alan)

    assert_equal [ "Alan Turing", "Grace Hopper", "Ada Lovelace" ], RecentPeopleQuery.call.map(&:name)
  end

  test "lists each person once using their latest association" do
    create_entry!(title: "Ada old", occurred_on: Date.new(2020, 1, 1), primary: @ada)
    create_entry!(
      title: "Ada and Grace",
      occurred_on: Date.new(2024, 5, 1),
      primary: @ada,
      people: [ @ada, @grace ]
    )

    names = RecentPeopleQuery.call.map(&:name)
    assert_equal 1, names.count("Ada Lovelace")
    assert_equal [ "Ada Lovelace", "Grace Hopper" ], names
  end

  test "limits to twenty unique people without placeholders" do
    people = 25.times.map do |i|
      Person.create!(name: "Person #{i.to_s.rjust(2, "0")}", slug: "person-#{i}")
    end

    people.each_with_index do |person, i|
      create_entry!(
        title: "Entry #{i}",
        occurred_on: Date.new(2024, 1, 1) + i.days,
        primary: person
      )
    end

    results = RecentPeopleQuery.call
    assert_equal 20, results.size
    assert_equal "Person 24", results.first.name
    assert_equal "Person 05", results.last.name
  end
end
