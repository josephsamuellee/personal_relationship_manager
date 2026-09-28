require "test_helper"

class EntriesControllerTest < ActionDispatch::IntegrationTest
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
  end
end
