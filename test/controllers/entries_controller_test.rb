require "test_helper"

class EntriesControllerTest < ActionDispatch::IntegrationTest
<<<<<<< HEAD
  setup do
    @person = Person.create!(name: "Ada Lovelace", slug: "ada-lovelace")
  end

  test "saving a new entry shows the successful save banner above Home" do
    post preview_entries_path, params: {
      entry: {
        title: "Tea with Ada",
        raw_date: "28 Sep 2026",
        body_markdown: "Tea with [[Ada Lovelace]]."
      }
    }
    assert_redirected_to preview_entries_path
    follow_redirect!
    assert_select "body.has-save-banner", count: 0
    assert_select "[data-controller=save-banner]", count: 0

    post entries_path
    entry = Entry.order(:id).last
    assert_redirected_to entry_path(entry)

    follow_redirect!
    assert_response :success
    assert_select "body.has-save-banner"
    assert_select ".flash.flash-notice.flash-save-success[data-controller=?]", "save-banner", text: "Entry saved."
    assert_select ".floating-nav-top a", text: "Home"
  end

  test "other notices do not shift Home for the save banner" do
    get new_entry_path

    assert_response :success
    assert_select "body.has-save-banner", count: 0
    assert_select "[data-controller=save-banner]", count: 0
    assert_select ".floating-nav-top a", text: "Home"
=======
  test "new entry defaults occurred on to today" do
    travel_to Time.zone.local(2026, 9, 28, 12, 0, 0) do
      get new_entry_path

      assert_response :success
      assert_select "input[name='entry[raw_date]'][value=?]", "28 Sep 2026"
      assert_select "input[name='entry[title]'][data-controller='autofocus']", count: 0
    end
  end

  test "new entry prefills occurred on from query param" do
    travel_to Time.zone.local(2026, 9, 28, 12, 0, 0) do
      get new_entry_path(occurred_on: "2026-09-25")

      assert_response :success
      assert_select "input[name='entry[raw_date]'][value=?]", "25 Sep 2026"
      assert_select "input[name='entry[title]'][data-controller=?]", "autofocus"
    end
  end

  test "new entry ignores invalid occurred on query param" do
    travel_to Time.zone.local(2026, 9, 28, 12, 0, 0) do
      get new_entry_path(occurred_on: "not-a-date")

      assert_response :success
      assert_select "input[name='entry[raw_date]'][value=?]", "28 Sep 2026"
      assert_select "input[name='entry[title]'][data-controller=?]", "autofocus"
    end
  end

  test "new entry prefers session draft over occurred on query param" do
    travel_to Time.zone.local(2026, 9, 28, 12, 0, 0) do
      post preview_entries_path, params: {
        entry: {
          title: "Draft title",
          raw_date: "10 Sep 2026",
          body_markdown: "[[Andrew]]"
        }
      }

      get new_entry_path(occurred_on: "2026-09-25")

      assert_response :success
      assert_select "input[name='entry[raw_date]'][value=?]", "10 Sep 2026"
      assert_select "input[name='entry[title]'][value=?]", "Draft title"
      assert_select "input[name='entry[title]'][data-controller=?]", "autofocus"
    end
>>>>>>> 08edbdb (Link homepage timeline day letters to new entry with date prefill)
  end
end
