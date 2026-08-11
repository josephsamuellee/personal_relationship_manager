require "test_helper"

class EntryTest < ActiveSupport::TestCase
  setup do
    @andrew = Person.create!(name: "Andrew", slug: "andrew")
    @sarah = Person.create!(name: "Sarah", slug: "sarah")
  end

  test "first wiki person becomes primary" do
    draft = EntryDraft.from_params(
      title: "Dinner",
      raw_date: "09 Aug 2026",
      body_markdown: "Dinner with [[Andrew]] and [[Sarah]]"
    )
    draft.person_selections = { "Andrew" => @andrew.id, "Sarah" => @sarah.id }
    draft.parse!

    entry = EntrySaver.save!(draft)
    assert_equal @andrew, entry.primary_person
    assert_equal [@andrew, @sarah], entry.people
  end

  test "shared entry appears for both people" do
    draft = EntryDraft.from_params(
      title: "Dinner",
      raw_date: "09 Aug 2026",
      body_markdown: "Dinner with [[Andrew]] and [[Sarah]]"
    )
    draft.person_selections = { "Andrew" => @andrew.id, "Sarah" => @sarah.id }
    draft.parse!

    entry = EntrySaver.save!(draft)
    assert_includes @andrew.entries, entry
    assert_includes @sarah.entries, entry
    assert_equal 1, Entry.count
  end

  test "edit preserves entry id and updates relationships" do
    draft = EntryDraft.from_params(
      title: "Dinner",
      raw_date: "09 Aug 2026",
      body_markdown: "Dinner with [[Andrew]]"
    )
    draft.person_selections = { "Andrew" => @andrew.id }
    draft.parse!
    entry = EntrySaver.save!(draft)

    edit_draft = EntryDraft.from_params(
      title: "Dinner updated",
      raw_date: "09 Aug 2026",
      body_markdown: "Dinner with [[Sarah]]",
      entry_id: entry.id
    )
    edit_draft.person_selections = { "Sarah" => @sarah.id }
    edit_draft.parse!

    updated = EntrySaver.save!(edit_draft)
    assert_equal entry.id, updated.id
    assert_equal @sarah, updated.primary_person
    assert_equal [@sarah], updated.people
  end

  test "from_session re-resolves people after person selections change" do
    draft = EntryDraft.from_params(
      title: "Dinner",
      raw_date: "09 Aug 2026",
      body_markdown: "Dinner with [[New Person]] and [[Another Person]]"
    )
    session_data = draft.to_session
    assert_equal 2, draft.unresolved_people.size

    session_data["person_selections"] = { "New Person" => @andrew.id, "Another Person" => @sarah.id }
    reloaded = EntryDraft.from_session(session_data)

    assert reloaded.valid_for_save?
    assert_empty reloaded.unresolved_people
    assert_equal [@andrew.id, @sarah.id], reloaded.resolved_people_ids
  end
end
