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

    draft.replace_person_link!("foobra", "Foobar")

    assert_includes draft.body_markdown, "[[Foobar]]"
    assert_not_includes draft.body_markdown, "[[foobra]]"
    assert draft.unresolved_people.empty?
    assert draft.valid_for_save?
    assert_equal @person.id, draft.resolved_people_ids.first
  end
end
