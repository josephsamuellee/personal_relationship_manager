require "test_helper"

class SettingFavoritePeopleTest < ActiveSupport::TestCase
  setup do
    @andrew = Person.create!(name: "Andrew", slug: "andrew")
    @carolyn = Person.create!(name: "Carolyn", slug: "carolyn")
    @jerry = Person.create!(name: "Jerry", slug: "jerry")
  end

  test "all three favorite slots default to unassigned" do
    assert_equal 0, Setting.count
    assert_equal [ nil, nil, nil ], Setting.favorite_person_ids
    assert_equal [ nil, nil, nil ], Setting.favorite_people
  end

  test "assigning person to slot 1 persists the assignment" do
    Setting.assign_favorite_slot!(@andrew, 1)

    assert_equal [ @andrew.id, nil, nil ], Setting.favorite_person_ids
    assert_equal [ @andrew, nil, nil ], Setting.favorite_people
    assert_equal 1, Setting.favorite_slot_for(@andrew)
  end

  test "assigning to slots 2 and 3 works" do
    Setting.assign_favorite_slot!(@carolyn, 2)
    Setting.assign_favorite_slot!(@jerry, 3)

    assert_equal [ nil, @carolyn.id, @jerry.id ], Setting.favorite_person_ids
    assert_equal 2, Setting.favorite_slot_for(@carolyn)
    assert_equal 3, Setting.favorite_slot_for(@jerry)
  end

  test "changing a favorite back to not favorited clears the slot" do
    Setting.assign_favorite_slot!(@andrew, 1)
    Setting.assign_favorite_slot!(@carolyn, 2)
    Setting.assign_favorite_slot!(@jerry, 3)

    Setting.assign_favorite_slot!(@andrew, "")

    assert_equal [ nil, @carolyn.id, @jerry.id ], Setting.favorite_person_ids
    assert_nil Setting.favorite_slot_for(@andrew)
  end

  test "moving a person from one slot to another clears their previous slot" do
    Setting.assign_favorite_slot!(@andrew, 1)
    Setting.assign_favorite_slot!(@andrew, 3)

    assert_equal [ nil, nil, @andrew.id ], Setting.favorite_person_ids
    assert_equal 3, Setting.favorite_slot_for(@andrew)
  end

  test "assigning a person to an occupied slot replaces the previous occupant" do
    Setting.assign_favorite_slot!(@andrew, 1)
    Setting.assign_favorite_slot!(@carolyn, 1)

    assert_equal [ @carolyn.id, nil, nil ], Setting.favorite_person_ids
    assert_nil Setting.favorite_slot_for(@andrew)
    assert_equal 1, Setting.favorite_slot_for(@carolyn)
  end

  test "one person cannot occupy multiple slots" do
    Setting.assign_favorite_slot!(@andrew, 1)
    Setting.assign_favorite_slot!(@andrew, 2)

    ids = Setting.favorite_person_ids
    assert_equal 1, ids.compact.size
    assert_equal [ nil, @andrew.id, nil ], ids
  end

  test "deleted person references do not break favorite_people and are cleaned up" do
    Setting.assign_favorite_slot!(@andrew, 1)
    Setting.assign_favorite_slot!(@carolyn, 2)
    deleted_id = @andrew.id
    @andrew.destroy!

    people = Setting.favorite_people

    assert_equal [ nil, @carolyn, nil ], people
    assert_equal [ nil, @carolyn.id, nil ], Setting.favorite_person_ids
    refute_includes Setting.favorite_person_ids, deleted_id
  end

  test "invalid favorite slot raises" do
    assert_raises(ArgumentError) { Setting.assign_favorite_slot!(@andrew, 4) }
    assert_raises(ArgumentError) { Setting.assign_favorite_slot!(@andrew, "nope") }
  end
end
