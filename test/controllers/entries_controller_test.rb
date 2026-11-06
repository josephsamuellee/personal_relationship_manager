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
  end

  test "new entry exposes compact occurred on controls and app-zone today" do
    travel_to Time.zone.local(2026, 10, 13, 12, 0, 0) do
      get new_entry_path

      assert_response :success
      assert_select ".occurred-on-field[data-controller=?]", "entry-date"
      assert_select ".occurred-on-field[data-entry-date-today-value=?]", "2026-10-13"
      assert_select ".occurred-on-field[data-entry-date-today-display-value=?]", "13 Oct 2026"
      assert_select ".occurred-on-row label", text: "Occurred On"
      assert_select ".occurred-on-row input[name='entry[raw_date]']"
      assert_select ".occurred-on-row button[data-action=?]", "entry-date#useToday", text: "Use Today"
      assert_select ".occurred-on-row button[data-action=?]", "entry-date#togglePicker", text: "Pick Date"
      assert_select ".occurred-on-error[data-entry-date-target=?]", "error"
      assert_select ".date-picker[data-entry-date-target=?]", "picker"
    end
  end

  test "edit entry exposes the same occurred on picker controls without saving on GET" do
    entry = create_entry!(
      title: "Existing",
      occurred_on: Date.new(2020, 3, 15),
      primary: @person,
      body: "Note with [[Ada Lovelace]]."
    )

    assert_no_changes -> { entry.reload.occurred_on } do
      get edit_entry_path(entry)
    end

    assert_response :success
    assert_select ".occurred-on-field[data-controller=?]", "entry-date"
    assert_select "input[name='entry[raw_date]'][value=?]", "15 Mar 2020"
    assert_select ".occurred-on-row button[data-action=?]", "entry-date#useToday", text: "Use Today"
    assert_select ".occurred-on-row button[data-action=?]", "entry-date#togglePicker", text: "Pick Date"
  end

  test "new and edit entry mount the markdown editor field for body markdown" do
    get new_entry_path
    assert_response :success
    assert_select ".markdown-editor-field[data-controller=?]", "markdown-editor"
    assert_select "textarea[name='entry[body_markdown]'][data-markdown-editor-target=?]", "fallback"
    assert_select "textarea[name='entry[body_markdown]'][required]"

    entry = create_entry!(
      title: "Existing",
      occurred_on: Date.new(2020, 3, 15),
      primary: @person,
      body: "Dinner with [[Ada Lovelace]].\n\n#dinner\n"
    )
    get edit_entry_path(entry)
    assert_response :success
    assert_select ".markdown-editor-field[data-controller=?]", "markdown-editor"
    assert_select "textarea[name='entry[body_markdown]']", text: "Dinner with [[Ada Lovelace]].\n\n#dinner\n"
  end

  test "markdown editor theme value follows light and dark settings" do
    Setting.update_theme("light")
    get new_entry_path
    assert_response :success
    assert_select ".markdown-editor-field[data-markdown-editor-theme-value=?]", "light"

    Setting.update_theme("dark")
    get new_entry_path
    assert_response :success
    assert_select ".markdown-editor-field[data-markdown-editor-theme-value=?]", "dark"
  end

  test "application.js does not eagerly import overtype" do
    source = Rails.root.join("app/javascript/application.js").read
    refute_match(/\bovertype\b/, source)
  end

  test "preview preserves wiki links hashtags and trailing newlines for no-op body" do
    body = "Dinner with [[Ada Lovelace]].\n\n#church\n"
    entry = create_entry!(
      title: "Existing",
      occurred_on: Date.new(2020, 3, 15),
      primary: @person,
      body: body
    )

    post preview_entry_path(entry), params: {
      entry: {
        entry_id: entry.id,
        title: entry.title,
        raw_date: entry.occurred_on.strftime("%d %b %Y"),
        body_markdown: body
      }
    }
    assert_redirected_to preview_entries_path
    follow_redirect!

    draft = session[:entry_draft]
    assert_equal body, draft["body_markdown"]
    assert_includes draft["parsed_people"], "Ada Lovelace"
    assert_includes draft["parsed_tags"], "church"
  end
end
