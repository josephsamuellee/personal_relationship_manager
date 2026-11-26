require "test_helper"

class ConfigUnfinishedDraftsTest < ActionDispatch::IntegrationTest
  setup do
    @person = Person.create!(name: "Ada Lovelace", slug: "ada-lovelace")
  end

  test "config lists unfinished drafts sorted by most recent modification" do
    older = PersistentEntryDraft.create!(
      title: "Older draft",
      raw_date: "01 Jan 2020",
      body_markdown: "[[Ada Lovelace]]",
      content_updated_at: 2.hours.ago
    )
    newer = PersistentEntryDraft.create!(
      title: "Newer draft",
      raw_date: "02 Jan 2020",
      body_markdown: "[[Ada Lovelace]]",
      content_updated_at: 1.hour.ago
    )
    older_updated = older.content_updated_at

    get config_path
    assert_response :success
    assert_select "h2", text: "Unfinished Drafts"
    assert_select "#unfinished-drafts tr[data-draft-id]", count: 2

    ids = css_select("#unfinished-drafts tbody tr[data-draft-id]").map { |row| row["data-draft-id"].to_i }
    assert_equal [ newer.id, older.id ], ids
    assert_equal older_updated.to_i, older.reload.content_updated_at.to_i

    assert_select "#unfinished-drafts a[href=?]", edit_entry_draft_path(newer), text: "Resume"
  end

  test "config discard with return_to config removes only selected draft" do
    keep = PersistentEntryDraft.create!(
      title: "Keep",
      raw_date: "01 Jan 2020",
      body_markdown: "[[Ada Lovelace]]",
      content_updated_at: 1.hour.ago
    )
    drop = PersistentEntryDraft.create!(
      title: "Drop",
      raw_date: "02 Jan 2020",
      body_markdown: "[[Ada Lovelace]]",
      content_updated_at: 30.minutes.ago
    )

    delete discard_draft_entries_path, params: { draft_id: drop.id, return_to: "config" }
    assert_redirected_to config_path
    assert PersistentEntryDraft.exists?(keep.id)
    refute PersistentEntryDraft.exists?(drop.id)
  end

  test "config resume link does not bump content_updated_at" do
    draft = PersistentEntryDraft.create!(
      title: "Stable",
      raw_date: "01 Jan 2020",
      body_markdown: "[[Ada Lovelace]]",
      content_updated_at: Time.zone.parse("2020-01-01 12:00:00")
    )
    stamped = draft.content_updated_at

    get config_path
    assert_response :success
    get edit_entry_draft_path(draft)
    assert_response :success
    assert_equal stamped.to_i, draft.reload.content_updated_at.to_i
  end

  test "config shows empty state when no drafts" do
    get config_path
    assert_response :success
    assert_select "#unfinished-drafts", text: /No unfinished drafts/
  end
end
