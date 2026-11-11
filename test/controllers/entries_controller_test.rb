require "test_helper"

class EntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @person = Person.create!(name: "Ada Lovelace", slug: "ada-lovelace")
  end

  test "new entry form posts Save to create without a Preview button" do
    get new_entry_path

    assert_response :success
    assert_select "form.entry-form[action=?][method=?]", entries_path, "post"
    assert_select "input[type=submit][value=?][data-turbo-submits-with=?]", "Save", "Saving..."
    assert_select "input[type=submit][value=?]", "Preview", count: 0
  end

  test "edit entry form patches Save without a Preview button" do
    entry = create_entry!(
      title: "Existing",
      occurred_on: Date.new(2020, 3, 15),
      primary: @person,
      body: "Note with [[Ada Lovelace]]."
    )

    get edit_entry_path(entry)

    assert_response :success
    assert_select "form.entry-form[action=?]", entry_path(entry)
    assert_select "input[type=submit][value=?][data-turbo-submits-with=?]", "Save", "Saving..."
    assert_select "input[type=submit][value=?]", "Preview", count: 0
    assert_select "input[name='entry[entry_id]'][value=?]", entry.id.to_s
  end

  test "direct save creates a new entry and shows the save banner" do
    assert_difference -> { Entry.count }, 1 do
      post entries_path, params: {
        entry: {
          title: "Tea with Ada",
          raw_date: "28 Sep 2026",
          body_markdown: "Tea with [[Ada Lovelace]]."
        }
      }
    end

    entry = Entry.order(:id).last
    assert_redirected_to entry_path(entry)
    assert_nil session[:entry_draft]

    follow_redirect!
    assert_response :success
    assert_select "body.has-save-banner"
    assert_select ".flash.flash-notice.flash-save-success[data-controller=?]", "save-banner", text: "Entry saved."
    assert_select ".floating-nav-top a", text: "Home"
  end

  test "direct save updates an existing entry without creating another" do
    entry = create_entry!(
      title: "Existing",
      occurred_on: Date.new(2020, 3, 15),
      primary: @person,
      body: "Note with [[Ada Lovelace]]."
    )

    assert_no_difference -> { Entry.count } do
      patch entry_path(entry), params: {
        entry: {
          entry_id: entry.id,
          title: "Updated title",
          raw_date: "16 Mar 2020",
          body_markdown: "Updated with [[Ada Lovelace]]."
        }
      }
    end

    assert_redirected_to entry_path(entry)
    assert_nil session[:entry_draft]
    entry.reload
    assert_equal "Updated title", entry.title
    assert_equal Date.new(2020, 3, 16), entry.occurred_on
    assert_equal "Updated with [[Ada Lovelace]].", entry.body_markdown

    follow_redirect!
    assert_select ".flash.flash-notice", text: "Entry updated."
  end

  test "no-op direct save preserves exact markdown body" do
    body = "Dinner with [[Ada Lovelace]].\n\n#church\n"
    entry = create_entry!(
      title: "Existing",
      occurred_on: Date.new(2020, 3, 15),
      primary: @person,
      body: body
    )

    patch entry_path(entry), params: {
      entry: {
        entry_id: entry.id,
        title: entry.title,
        raw_date: entry.occurred_on.strftime("%d %b %Y"),
        body_markdown: body
      }
    }

    assert_redirected_to entry_path(entry)
    assert_equal body, entry.reload.body_markdown
  end

  test "resolution save without body params persists a staged valid draft" do
    post preview_entries_path, params: {
      entry: {
        title: "Staged tea",
        raw_date: "28 Sep 2026",
        body_markdown: "Tea with [[Ada Lovelace]]."
      }
    }
    assert_redirected_to preview_entries_path
    assert session[:entry_draft].present?

    assert_difference -> { Entry.count }, 1 do
      post entries_path
    end

    entry = Entry.order(:id).last
    assert_redirected_to entry_path(entry)
    assert_nil session[:entry_draft]
    assert_equal "Staged tea", entry.title
  end

  test "unknown person on direct save stages draft and redirects to resolution UI" do
    assert_no_difference -> { Entry.count } do
      post entries_path, params: {
        entry: {
          title: "Mystery meeting",
          raw_date: "28 Sep 2026",
          body_markdown: "Met [[Unknown Person]]."
        }
      }
    end

    assert_redirected_to preview_entries_path
    assert session[:entry_draft].present?
    follow_redirect!
    assert_select ".resolution-panel", text: /No person named "Unknown Person"/
  end

  test "ambiguous person on direct save stages draft without persisting" do
    first = Person.create!(name: "Alex One")
    first.update_columns(name: "Alex", slug: "alex-one")
    second = Person.create!(name: "Alex Two")
    second.update_columns(name: "Alex", slug: "alex-two")

    assert_no_difference -> { Entry.count } do
      post entries_path, params: {
        entry: {
          title: "Ambiguous",
          raw_date: "28 Sep 2026",
          body_markdown: "Hello [[Alex]]."
        }
      }
    end

    assert_redirected_to preview_entries_path
    follow_redirect!
    assert_select ".resolution-panel", text: /matches multiple people/
  end

  test "unknown person on edit save redirects to resolution without updating" do
    entry = create_entry!(
      title: "Existing",
      occurred_on: Date.new(2020, 3, 15),
      primary: @person,
      body: "Note with [[Ada Lovelace]]."
    )

    assert_no_changes -> { entry.reload.body_markdown } do
      patch entry_path(entry), params: {
        entry: {
          entry_id: entry.id,
          title: "Existing",
          raw_date: "15 Mar 2020",
          body_markdown: "Met [[Brand New Person]]."
        }
      }
    end

    assert_redirected_to preview_entries_path
    assert_equal entry.id, session[:entry_draft].with_indifferent_access[:entry_id]
  end

  test "validation failure without unresolved people re-renders new form" do
    assert_no_difference -> { Entry.count } do
      post entries_path, params: {
        entry: {
          title: "",
          raw_date: "28 Sep 2026",
          body_markdown: "Tea with [[Ada Lovelace]]."
        }
      }
    end

    assert_response :unprocessable_entity
    assert_nil session[:entry_draft]
    assert_select "form.entry-form"
    assert_select "li", text: /Title cannot be blank/
    assert_select "textarea[name='entry[body_markdown]']", text: "Tea with [[Ada Lovelace]]."
  end

  test "missing person validation re-renders edit form" do
    entry = create_entry!(
      title: "Existing",
      occurred_on: Date.new(2020, 3, 15),
      primary: @person,
      body: "Note with [[Ada Lovelace]]."
    )

    patch entry_path(entry), params: {
      entry: {
        entry_id: entry.id,
        title: "Existing",
        raw_date: "15 Mar 2020",
        body_markdown: "No person links here."
      }
    }

    assert_response :unprocessable_entity
    assert_select "li", text: /at least one person link/
    assert_select "textarea[name='entry[body_markdown]']", text: "No person links here."
  end

  test "invalid date without unresolved people re-renders form" do
    assert_no_difference -> { Entry.count } do
      post entries_path, params: {
        entry: {
          title: "Bad date",
          raw_date: "not-a-date",
          body_markdown: "Tea with [[Ada Lovelace]]."
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "input[name='entry[raw_date]'][value=?]", "not-a-date"
  end

  test "unknown person with invalid date prefers resolution UI and preserves errors" do
    assert_no_difference -> { Entry.count } do
      post entries_path, params: {
        entry: {
          title: "Both problems",
          raw_date: "not-a-date",
          body_markdown: "Met [[Unknown Person]]."
        }
      }
    end

    assert_redirected_to preview_entries_path
    draft = session[:entry_draft].with_indifferent_access
    assert_includes draft[:body_markdown], "[[Unknown Person]]"
    assert_equal "not-a-date", draft[:raw_date]
    assert draft[:validation_errors].any?

    follow_redirect!
    assert_select ".resolution-panel"
    assert_select ".preview-status-list li", text: /not-a-date|recognized date format/i
  end

  test "direct save adds and removes person associations without preview" do
    sarah = Person.create!(name: "Sarah", slug: "sarah")
    entry = create_entry!(
      title: "Dinner",
      occurred_on: Date.new(2020, 3, 15),
      primary: @person,
      people: [ @person ],
      body: "Dinner with [[Ada Lovelace]]."
    )

    patch entry_path(entry), params: {
      entry: {
        entry_id: entry.id,
        title: "Dinner",
        raw_date: "15 Mar 2020",
        body_markdown: "Dinner with [[Ada Lovelace]] and [[Sarah]]."
      }
    }
    assert_redirected_to entry_path(entry)
    entry.reload
    assert_equal [ @person.id, sarah.id ], entry.entry_people.order(:position).pluck(:person_id)

    patch entry_path(entry), params: {
      entry: {
        entry_id: entry.id,
        title: "Dinner",
        raw_date: "15 Mar 2020",
        body_markdown: "Dinner with [[Sarah]]."
      }
    }
    assert_redirected_to entry_path(entry)
    entry.reload
    assert_equal [ sarah.id ], entry.entry_people.order(:position).pluck(:person_id)
    assert_equal sarah.id, entry.primary_person_id
    assert Person.exists?(@person.id)
  end

  test "create person on resolution then save persists and clears draft" do
    post entries_path, params: {
      entry: {
        title: "New friend",
        raw_date: "28 Sep 2026",
        body_markdown: "Met [[New Friend]]."
      }
    }
    assert_redirected_to preview_entries_path

    post create_person_entries_path, params: { name: "New Friend" }
    assert_redirected_to preview_entries_path
    assert Person.exists?(name: "New Friend")

    assert_difference -> { Entry.count }, 1 do
      post entries_path
    end

    entry = Entry.order(:id).last
    assert_redirected_to entry_path(entry)
    assert_nil session[:entry_draft]
    assert_equal "New Friend", entry.primary_person.name
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

  test "new entry seeds markdown body from body query param" do
    get new_entry_path(occurred_on: "2026-11-12", body: "Dinner with Jerry")

    assert_response :success
    assert_select "input[name='entry[raw_date]'][value=?]", "12 Nov 2026"
    assert_select "textarea[name='entry[body_markdown]']", text: "Dinner with Jerry"
  end

  test "new entry preserves special characters in body seed" do
    title = 'Café & <friends> say "hi" **bold**'
    get new_entry_path(occurred_on: "2026-11-13", body: title)

    assert_response :success
    textarea = css_select("textarea[name='entry[body_markdown]']").first
    assert_equal title, textarea.text
    refute_includes response.body, "<script>"
  end

  test "new entry body seed does not persist an entry by itself" do
    assert_no_difference("Entry.count") do
      get new_entry_path(occurred_on: "2026-11-12", body: "Family Vacation")
      assert_response :success
    end
  end

  test "session draft takes precedence over body seed" do
    post preview_entries_path, params: {
      entry: {
        title: "Draft title",
        raw_date: "10 Sep 2026",
        body_markdown: "Existing draft body"
      }
    }

    get new_entry_path(occurred_on: "2026-11-12", body: "Dinner with Jerry")

    assert_response :success
    assert_select "textarea[name='entry[body_markdown]']", text: "Existing draft body"
  end

  test "validation failure keeps seeded date and body available" do
    post entries_path, params: {
      entry: {
        title: "",
        raw_date: "12 Nov 2026",
        body_markdown: "Dinner with Jerry"
      }
    }

    assert_response :unprocessable_entity
    assert_select "input[name='entry[raw_date]'][value=?]", "12 Nov 2026"
    assert_select "textarea[name='entry[body_markdown]']", text: "Dinner with Jerry"
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

  test "entry form CSS doubles editor height without changing shared about default" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read
    assert_match(/\.entry-form \.markdown-editor-mount[\s\S]*min-height:\s*24rem/, css)
    assert_match(/\.markdown-editor-mount \{[\s\S]*min-height:\s*12rem/, css)
  end

  test "new and edit show recent people buttons below Save ranked by latest association" do
    older = Person.create!(name: "Older Friend", slug: "older-friend")
    newer = Person.create!(name: "Newer Friend", slug: "newer-friend")
    Person.create!(name: "Unlinked", slug: "unlinked")
    create_entry!(title: "Old", occurred_on: Date.new(2020, 1, 1), primary: older)
    create_entry!(title: "New", occurred_on: Date.new(2024, 1, 1), primary: newer)

    get new_entry_path
    assert_response :success
    assert_select "form.entry-form[data-controller=?]", "recent-people"
    assert_select ".recent-people" do
      assert_select "button.recent-people-button[type=button]", count: 2
      assert_select "button.recent-people-button", text: "Newer Friend"
      assert_select "button.recent-people-button", text: "Older Friend"
      assert_select "button.recent-people-button", text: "Ada Lovelace", count: 0
      assert_select "button.recent-people-button", text: "Unlinked", count: 0
      assert_select "a", count: 0
    end
    assert_select "form.entry-form input[type=submit][value=Save] ~ .recent-people"

    entry = create_entry!(
      title: "Existing",
      occurred_on: Date.new(2021, 1, 1),
      primary: @person,
      body: "Note with [[Ada Lovelace]]."
    )
    get edit_entry_path(entry)
    assert_response :success
    assert_select "form.entry-form input[type=submit][value=Save] ~ .recent-people"
    assert_select ".recent-people button.recent-people-button[type=button]", minimum: 1
  end

  test "recent people section is omitted when nobody has been referenced" do
    # setup creates Ada but no saved Entry associations
    get new_entry_path
    assert_response :success
    assert_select ".recent-people", count: 0
    assert_select ".recent-people-button", count: 0
  end

  test "save persists body that includes a recent-people style wiki insert" do
    assert_difference -> { Entry.count }, 1 do
      post entries_path, params: {
        entry: {
          title: "Inserted ref",
          raw_date: "28 Sep 2026",
          body_markdown: "Met [[Ada Lovelace]]."
        }
      }
    end

    entry = Entry.order(:id).last
    assert_equal "Met [[Ada Lovelace]].", entry.body_markdown
    assert_redirected_to entry_path(entry)
  end
end
