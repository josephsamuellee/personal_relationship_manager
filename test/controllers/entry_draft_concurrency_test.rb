require "test_helper"

class EntryDraftConcurrencyTest < ActionDispatch::IntegrationTest
  setup do
    @person = Person.create!(name: "Ada Lovelace", slug: "ada-lovelace")
  end

  test "create with same client_create_id is idempotent" do
    create_id = SecureRandom.uuid

    assert_difference -> { PersistentEntryDraft.count }, 1 do
      post entry_drafts_path,
           params: {
             entry_draft: {
               title: "First",
               raw_date: "01 Jan 2020",
               body_markdown: "Hello [[Ada Lovelace]]",
               client_create_id: create_id
             }
           },
           as: :json
    end
    assert_response :created
    first = JSON.parse(response.body)

    assert_no_difference -> { PersistentEntryDraft.count } do
      post entry_drafts_path,
           params: {
             entry_draft: {
               title: "Retry different",
               raw_date: "02 Jan 2020",
               body_markdown: "Retry [[Ada Lovelace]]",
               client_create_id: create_id
             }
           },
           as: :json
    end
    assert_response :success
    second = JSON.parse(response.body)

    assert_equal first["id"], second["id"]
    record = PersistentEntryDraft.find(first["id"])
    assert_equal "First", record.title
    assert_equal create_id, record.client_create_id
  end

  test "stale autosave is rejected with 409 and does not overwrite" do
    record = PersistentEntryDraft.create!(
      title: "Base",
      raw_date: "01 Jan 2020",
      body_markdown: "v1 [[Ada Lovelace]]"
    )
    stale = record.lock_version

    patch entry_draft_path(record),
          params: {
            entry_draft: {
              title: "Winner",
              raw_date: "01 Jan 2020",
              body_markdown: "v2 [[Ada Lovelace]]",
              lock_version: stale
            }
          },
          as: :json
    assert_response :success
    winner_version = JSON.parse(response.body)["lock_version"]

    patch entry_draft_path(record),
          params: {
            entry_draft: {
              title: "Stale",
              raw_date: "01 Jan 2020",
              body_markdown: "stale [[Ada Lovelace]]",
              lock_version: stale
            }
          },
          as: :json
    assert_response :conflict
    body = JSON.parse(response.body)
    assert_equal "conflict", body["error"]
    assert_equal "Winner", body["title"]
    assert_equal "v2 [[Ada Lovelace]]", body["body_markdown"]
    assert_equal winner_version, body["lock_version"]

    record.reload
    assert_equal "Winner", record.title
    assert_equal "v2 [[Ada Lovelace]]", record.body_markdown
  end

  test "stale final Save is rejected without persisting Entry or overwriting draft" do
    record = PersistentEntryDraft.create!(
      title: "Draft",
      raw_date: "15 Mar 2020",
      body_markdown: "Met [[Ada Lovelace]].",
      client_create_id: SecureRandom.uuid
    )
    stale = record.lock_version

    patch entry_draft_path(record),
          params: {
            entry_draft: {
              title: "Newer draft",
              raw_date: "15 Mar 2020",
              body_markdown: "Newer [[Ada Lovelace]].",
              lock_version: stale
            }
          },
          as: :json
    assert_response :success

    assert_no_difference -> { Entry.count } do
      post entries_path, params: {
        entry: {
          title: "Stale save",
          raw_date: "15 Mar 2020",
          body_markdown: "Stale [[Ada Lovelace]].",
          draft_id: record.id,
          lock_version: stale
        }
      }
    end
    assert_response :unprocessable_entity
    assert_match(/Conflict detected/i, flash[:alert].to_s + response.body)

    record.reload
    assert_equal "Newer draft", record.title
    assert PersistentEntryDraft.exists?(record.id)
  end

  test "stale discard is rejected and draft remains" do
    record = PersistentEntryDraft.create!(
      title: "Keep me",
      raw_date: "01 Jan 2020",
      body_markdown: "[[Ada Lovelace]]"
    )
    stale = record.lock_version

    patch entry_draft_path(record),
          params: {
            entry_draft: {
              title: "Updated",
              raw_date: "01 Jan 2020",
              body_markdown: "Updated [[Ada Lovelace]]",
              lock_version: stale
            }
          },
          as: :json
    assert_response :success

    assert_no_difference -> { PersistentEntryDraft.count } do
      delete discard_draft_entries_path, params: { draft_id: record.id, lock_version: stale }
    end
    assert_redirected_to edit_entry_draft_path(record)
    assert_match(/Conflict detected/i, flash[:alert])
    assert PersistentEntryDraft.exists?(record.id)
  end

  test "autosave after discard returns gone and does not recreate" do
    record = PersistentEntryDraft.create!(
      title: "Gone",
      raw_date: "01 Jan 2020",
      body_markdown: "[[Ada Lovelace]]"
    )
    id = record.id
    version = record.lock_version
    record.destroy!

    assert_no_difference -> { PersistentEntryDraft.count } do
      patch entry_draft_path(id),
            params: {
              entry_draft: {
                title: "Resurrect",
                raw_date: "01 Jan 2020",
                body_markdown: "Nope [[Ada Lovelace]]",
                lock_version: version
              }
            },
            as: :json
    end
    assert_response :gone
  end

  test "autosave after successful Save returns gone and does not recreate" do
    draft = PersistentEntryDraft.create!(
      title: "Commit me",
      raw_date: "15 Mar 2020",
      body_markdown: "Met [[Ada Lovelace]]."
    )
    id = draft.id
    version = draft.lock_version

    post entries_path, params: { draft_id: draft.id, lock_version: version }
    assert_redirected_to entry_path(Entry.last)
    assert_not PersistentEntryDraft.exists?(id)

    assert_no_difference -> { PersistentEntryDraft.count } do
      patch entry_draft_path(id),
            params: {
              entry_draft: {
                title: "Late",
                raw_date: "15 Mar 2020",
                body_markdown: "Late [[Ada Lovelace]].",
                lock_version: version
              }
            },
            as: :json
    end
    assert_response :gone
  end
end
