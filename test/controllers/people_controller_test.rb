require "test_helper"
require "minitest/mock"

class PeopleControllerTest < ActionDispatch::IntegrationTest
  setup do
    @andrew = Person.create!(name: "Andrew", slug: "andrew")
    @carolyn = Person.create!(name: "Carolyn", slug: "carolyn")
    @jerry = Person.create!(name: "Jerry", slug: "jerry")
  end

  test "people index lists all people alphabetically with links to person pages" do
    get people_path

    assert_response :success
    assert_select "h1", text: "People"

    names = css_select(".entry-list a").map { |node| node.text.strip }
    assert_equal %w[Andrew Carolyn Jerry], names
    assert_select "a[href=?]", person_path(@andrew), text: "Andrew"
    assert_select "a[href=?]", person_path(@carolyn), text: "Carolyn"
    assert_select "a[href=?]", person_path(@jerry), text: "Jerry"
  end

  test "person page defaults favorite dropdown to Not favorited" do
    get person_path(@andrew)

    assert_response :success
    assert_select "select#person_favorite_slot" do
      assert_select "option[value=''][selected]", text: "Not favorited"
      assert_select "option[value=1]", text: "1"
      assert_select "option[value=2]", text: "2"
      assert_select "option[value=3]", text: "3"
    end
  end

  test "assigning person to slot 1 and saving persists the assignment" do
    patch person_path(@andrew), params: {
      person: { about_markdown: "Notes", favorite_slot: "1" }
    }

    assert_redirected_to person_path(@andrew)
    assert_equal [ @andrew.id, nil, nil ], Setting.favorite_person_ids

    follow_redirect!
    assert_select "select#person_favorite_slot option[value=1][selected]"
  end

  test "assigning to slots 2 and 3 works via save" do
    patch person_path(@carolyn), params: {
      person: { about_markdown: @carolyn.about_markdown, favorite_slot: "2" }
    }
    patch person_path(@jerry), params: {
      person: { about_markdown: @jerry.about_markdown, favorite_slot: "3" }
    }

    assert_equal [ nil, @carolyn.id, @jerry.id ], Setting.favorite_person_ids
  end

  test "changing the dropdown without save does not persist" do
    get person_path(@andrew)
    assert_response :success
    assert_select "select#person_favorite_slot"

    assert_equal [ nil, nil, nil ], Setting.favorite_person_ids
  end

  test "changing a favorite back to Not favorited clears the slot" do
    Setting.assign_favorite_slot!(@andrew, 1)
    Setting.assign_favorite_slot!(@carolyn, 2)
    Setting.assign_favorite_slot!(@jerry, 3)

    patch person_path(@andrew), params: {
      person: { about_markdown: @andrew.about_markdown, favorite_slot: "" }
    }

    assert_redirected_to person_path(@andrew)
    assert_equal [ nil, @carolyn.id, @jerry.id ], Setting.favorite_person_ids
  end

  test "moving a person from one slot to another clears their previous slot" do
    Setting.assign_favorite_slot!(@andrew, 1)

    patch person_path(@andrew), params: {
      person: { about_markdown: @andrew.about_markdown, favorite_slot: "3" }
    }

    assert_equal [ nil, nil, @andrew.id ], Setting.favorite_person_ids
  end

  test "assigning a person to an occupied slot replaces the previous occupant" do
    Setting.assign_favorite_slot!(@andrew, 1)

    patch person_path(@carolyn), params: {
      person: { about_markdown: @carolyn.about_markdown, favorite_slot: "1" }
    }

    assert_equal [ @carolyn.id, nil, nil ], Setting.favorite_person_ids
    assert_nil Setting.favorite_slot_for(@andrew)
  end

  test "failed person save does not partially change favorite configuration" do
    Setting.assign_favorite_slot!(@carolyn, 2)

    Person.stub(:find, @andrew) do
      @andrew.stub(:update, false) do
        patch person_path(@andrew), params: {
          person: { about_markdown: "Should not save", favorite_slot: "1" }
        }
      end
    end

    assert_response :unprocessable_entity
    assert_equal [ nil, @carolyn.id, nil ], Setting.favorite_person_ids
    assert_select "select#person_favorite_slot option[value=1][selected]"
  end

  test "invalid favorite slot does not change configuration and redisplays selection" do
    Setting.assign_favorite_slot!(@carolyn, 2)

    patch person_path(@andrew), params: {
      person: { about_markdown: "Notes", favorite_slot: "9" }
    }

    assert_response :unprocessable_entity
    assert_equal [ nil, @carolyn.id, nil ], Setting.favorite_person_ids
    assert_match(/invalid favorite slot/, response.body)
    assert_select "select#person_favorite_slot option[value=9]", count: 0
  end
end
