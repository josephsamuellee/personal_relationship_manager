require "test_helper"

class EntryDraftTest < ActiveSupport::TestCase
  setup do
    @person = Person.create!(name: "Foobar", slug: "foobar")
  end

  test "unresolved_people includes suggestions for unknown names" do
    draft = EntryDraft.new(
      title: "Test",
      raw_date: "11 Aug 2026",
      body_markdown: "Met with [[foobra]] today."
    )
    draft.parse!

    unresolved = draft.unresolved_people
    assert_equal 1, unresolved.size
    assert unresolved.first[:result].unknown?
    assert_includes unresolved.first[:suggestions].map(&:name), "Foobar"
  end

  test "replace_person_link updates body and resolves person" do
    draft = EntryDraft.new(
      title: "Test",
      raw_date: "11 Aug 2026",
      body_markdown: "Met with [[foobra]] and [[foobra]] again."
    )
    draft.parse!
    assert draft.unresolved_people.any?
    assert_not draft.valid_for_save?

    draft.replace_person_link!("foobra", "Foobar")

    assert_includes draft.body_markdown, "[[Foobar]]"
    assert_not_includes draft.body_markdown, "[[foobra]]"
    assert draft.unresolved_people.empty?
    assert draft.valid_for_save?
    assert_equal @person.id, draft.resolved_people_ids.first
  end

  test "partial name match stays unresolved until user confirms" do
    draft = EntryDraft.new(
      title: "Test",
      raw_date: "11 Aug 2026",
      body_markdown: "Met with [[foobra]] today."
    )
    draft.parse!

    assert_nil draft.resolved_people_ids.first
    assert draft.unresolved_people.any?
  end

  test "from_record re-parses and re-resolves people" do
    record = PersistentEntryDraft.create!(
      title: "From record",
      raw_date: "11 Aug 2026",
      body_markdown: "Met with [[Foobar]].",
      person_selections: {}
    )

    draft = EntryDraft.from_record(record)
    assert_equal record.id, draft.persistent_draft_id
    assert_equal "From record", draft.title
    assert_equal "Met with [[Foobar]].", draft.body_markdown
    assert_equal @person.id, draft.resolved_people_ids.first
    assert draft.valid_for_save?
  end

  test "persist! stores durable draft and sets persistent_draft_id" do
    draft = EntryDraft.from_params(
      title: "Persist me",
      raw_date: "11 Aug 2026",
      body_markdown: "Met [[Unknown]]."
    )

    assert_difference -> { PersistentEntryDraft.count }, 1 do
      record = draft.persist!
      assert_equal record.id, draft.persistent_draft_id
      assert_equal "Persist me", record.title
      assert_equal "Met [[Unknown]].", record.body_markdown
    end
  end
end
