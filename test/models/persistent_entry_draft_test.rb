require "test_helper"

class PersistentEntryDraftTest < ActiveSupport::TestCase
  test "round trips title raw_date body and selections without creating Entry or Person" do
    assert_no_difference -> { Entry.count } do
      assert_no_difference -> { Person.count } do
        record = PersistentEntryDraft.create!(
          title: "Tea notes",
          raw_date: "not-a-date-yet",
          body_markdown: "Met [[Unknown Person]].",
          person_selections: { "Unknown Person" => "12" }
        )

        reloaded = PersistentEntryDraft.find(record.id)
        assert_equal "Tea notes", reloaded.title
        assert_equal "not-a-date-yet", reloaded.raw_date
        assert_equal "Met [[Unknown Person]].", reloaded.body_markdown
        assert_equal({ "Unknown Person" => "12" }, reloaded.person_selections_hash)
        assert reloaded.lock_version.is_a?(Integer)
        assert_not_nil reloaded.content_updated_at
      end
    end
  end

  test "upsert_from_entry_draft updates existing row by draft id" do
    draft = EntryDraft.from_params(
      title: "One",
      raw_date: "28 Sep 2026",
      body_markdown: "Hello [[Nobody]]."
    )
    record = PersistentEntryDraft.upsert_from_entry_draft!(draft)
    draft.persistent_draft_id = record.id
    draft.title = "Two"
    draft.body_markdown = "Updated [[Nobody]]."
    draft.parse!

    updated = PersistentEntryDraft.upsert_from_entry_draft!(draft, draft_id: record.id)
    assert_equal record.id, updated.id
    assert_equal "Two", updated.title
    assert_equal "Updated [[Nobody]].", updated.body_markdown
    assert_equal 1, PersistentEntryDraft.count
  end

  test "unique entry_id allows only one edit draft per Entry" do
    person = Person.create!(name: "Ada", slug: "ada")
    entry = create_entry!(title: "E", occurred_on: Date.new(2020, 1, 1), primary: person, body: "[[Ada]]")

    PersistentEntryDraft.create!(entry: entry, title: "A", raw_date: "01 Jan 2020", body_markdown: "[[Ada]]")
    assert_raises(ActiveRecord::RecordNotUnique) do
      PersistentEntryDraft.create!(entry: entry, title: "B", raw_date: "01 Jan 2020", body_markdown: "[[Ada]] again")
    end
  end

  test "captures base_entry_updated_at when binding to an entry" do
    person = Person.create!(name: "Ada", slug: "ada-2")
    entry = create_entry!(title: "E", occurred_on: Date.new(2020, 1, 1), primary: person, body: "[[Ada]]")

    record = PersistentEntryDraft.create!(
      entry: entry,
      title: "Edit",
      raw_date: "01 Jan 2020",
      body_markdown: "[[Ada]]"
    )
    assert_equal entry.updated_at.to_i, record.base_entry_updated_at.to_i
    assert_not record.entry_changed?

    travel 2.seconds do
      entry.update!(title: "Changed")
    end
    assert record.reload.entry_changed?
  end

  test "orphaned_edit when entry_id cleared but base timestamp remains" do
    record = PersistentEntryDraft.create!(
      title: "Orphan",
      raw_date: "01 Jan 2020",
      body_markdown: "[[Ada]]",
      base_entry_updated_at: 1.day.ago
    )
    assert record.orphaned_edit?
    assert_not record.new_entry_draft?
  end

  test "optimistic locking raises StaleObjectError on concurrent update" do
    record = PersistentEntryDraft.create!(
      title: "A",
      raw_date: "01 Jan 2020",
      body_markdown: "[[Ada]]"
    )
    first = PersistentEntryDraft.find(record.id)
    second = PersistentEntryDraft.find(record.id)

    first.title = "First"
    first.content_updated_at = Time.current
    first.save!

    second.title = "Second"
    second.content_updated_at = Time.current
    assert_raises(ActiveRecord::StaleObjectError) { second.save! }

    assert_equal "First", record.reload.title
  end

  test "client_create_id is unique" do
    PersistentEntryDraft.create!(
      title: "A",
      raw_date: "01 Jan 2020",
      body_markdown: "[[Ada]]",
      client_create_id: "same-id"
    )
    assert_raises(ActiveRecord::RecordNotUnique) do
      PersistentEntryDraft.create!(
        title: "B",
        raw_date: "01 Jan 2020",
        body_markdown: "[[Ada]]",
        client_create_id: "same-id"
      )
    end
  end
end
