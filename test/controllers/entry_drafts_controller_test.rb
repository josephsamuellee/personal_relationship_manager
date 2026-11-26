require "test_helper"

class EntryDraftsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @person = Person.create!(name: "Ada Lovelace", slug: "ada-lovelace")
  end

  test "create persists draft fields without Entry or Person side effects" do
    assert_no_difference -> { Entry.count } do
      assert_no_difference -> { Person.count } do
        assert_difference -> { PersistentEntryDraft.count }, 1 do
          post entry_drafts_path,
               params: {
                 entry_draft: {
                   title: "Autosaved",
                   raw_date: "partial",
                   body_markdown: "Met [[Unknown Person]]."
                 }
               },
               as: :json
        end
      end
    end

    assert_response :created
    body = JSON.parse(response.body)
    record = PersistentEntryDraft.find(body["id"])
    assert_equal "Autosaved", record.title
    assert_equal "partial", record.raw_date
    assert_equal "Met [[Unknown Person]].", record.body_markdown
    assert body["content_updated_at"].present?
    assert body.key?("lock_version")
    assert_equal edit_entry_draft_path(record), body["edit_url"]
  end

  test "update changes the same draft without creating people" do
    record = PersistentEntryDraft.create!(
      title: "One",
      raw_date: "01 Jan 2020",
      body_markdown: "Hello [[Nobody]]"
    )

    assert_no_difference -> { Person.count } do
      assert_no_difference -> { PersistentEntryDraft.count } do
        patch entry_draft_path(record),
              params: {
                entry_draft: {
                  title: "Two",
                  raw_date: "02 Jan 2020",
                  body_markdown: "Updated [[Nobody]]",
                  lock_version: record.lock_version
                }
              },
              as: :json
      end
    end

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal record.id, body["id"]
    record.reload
    assert_equal "Two", record.title
    assert_equal "Updated [[Nobody]]", record.body_markdown
  end

  test "create with entry_id reuses the unique edit draft row" do
    entry = create_entry!(
      title: "Existing",
      occurred_on: Date.new(2020, 3, 15),
      primary: @person,
      body: "Note with [[Ada Lovelace]]."
    )

    post entry_drafts_path,
         params: {
           entry_draft: {
             entry_id: entry.id,
             title: "Edited",
             raw_date: "15 Mar 2020",
             body_markdown: "Changed [[Ada Lovelace]]."
           }
         },
         as: :json
    assert_response :created
    first_id = JSON.parse(response.body)["id"]

    post entry_drafts_path,
         params: {
           entry_draft: {
             entry_id: entry.id,
             title: "Edited again",
             raw_date: "15 Mar 2020",
             body_markdown: "Changed again [[Ada Lovelace]]."
           }
         },
         as: :json
    assert_response :success
    second_id = JSON.parse(response.body)["id"]

    assert_equal first_id, second_id
    assert_equal 1, PersistentEntryDraft.where(entry_id: entry.id).count
    assert_equal "Edited again", PersistentEntryDraft.find(first_id).title
  end

  test "edit new draft resumes fields and keeps entries new blank without draft id" do
    record = PersistentEntryDraft.create!(
      title: "Resume me",
      raw_date: "10 Sep 2026",
      body_markdown: "Body [[Ada Lovelace]]"
    )

    get edit_entry_draft_path(record)
    assert_response :success
    assert_select "form.entry-form[data-controller*='entry-draft-autosave']"
    assert_select "input[name='entry[title]'][value=?]", "Resume me"
    assert_select "textarea[name='entry[body_markdown]']", text: "Body [[Ada Lovelace]]"
    assert_select "input[name='entry[draft_id]'][value=?]", record.id.to_s
    assert_select "[data-entry-draft-autosave-target=status]"

    get new_entry_path
    assert_response :success
    assert_select "input[name='entry[draft_id]']", count: 0
    title = css_select("input[name='entry[title]']").first
    assert title["value"].blank?
  end

  test "opening new entry does not create a durable draft" do
    assert_no_difference -> { PersistentEntryDraft.count } do
      get new_entry_path
      assert_response :success
    end
  end

  test "people about page does not mount entry draft autosave" do
    get person_path(@person)
    assert_response :success
    assert_select "form.entry-form[data-controller*=entry-draft-autosave]", count: 0
    assert_select "[data-controller=entry-draft-autosave]", count: 0
  end
end
