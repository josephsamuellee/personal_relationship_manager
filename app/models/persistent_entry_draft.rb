class PersistentEntryDraft < ApplicationRecord
  self.table_name = "entry_drafts"

  belongs_to :entry, optional: true

  before_validation :ensure_content_updated_at
  before_validation :normalize_person_selections
  before_validation :capture_base_entry_timestamp

  scope :most_recent_first, -> { order(content_updated_at: :desc, id: :desc) }

  def self.most_recent
    most_recent_first.first
  end

  def self.upsert_from_entry_draft!(entry_draft, draft_id: nil)
    record = find_for_upsert(draft_id: draft_id, entry_id: entry_draft.entry_id)
    record.assign_from_entry_draft(entry_draft)
    record.save!
    record
  end

  def self.find_for_upsert(draft_id:, entry_id:)
    if draft_id.present?
      find(draft_id)
    elsif entry_id.present?
      find_or_initialize_by(entry_id: entry_id)
    else
      new
    end
  end

  def self.find_or_initialize_for_create(client_create_id:, entry_id:)
    if client_create_id.present?
      existing = find_by(client_create_id: client_create_id)
      return existing if existing
    end

    record = if entry_id.present?
      find_or_initialize_by(entry_id: entry_id)
    else
      new
    end
    record.client_create_id ||= client_create_id.presence
    record
  end

  def assign_from_entry_draft(entry_draft)
    self.title = entry_draft.title
    self.raw_date = entry_draft.raw_date
    self.body_markdown = entry_draft.body_markdown.to_s
    self.entry_id = entry_draft.entry_id
    self.person_selections = stringify_selections(entry_draft.person_selections)
    self.content_updated_at = Time.current
  end

  def person_selections_hash
    raw = read_attribute(:person_selections)
    case raw
    when Hash
      raw.stringify_keys
    when String
      JSON.parse(raw.presence || "{}")
    else
      {}
    end
  rescue JSON::ParserError
    {}
  end

  def person_selections=(value)
    write_attribute(:person_selections, stringify_selections(value).to_json)
  end

  def orphaned_edit?
    entry_id.blank? && base_entry_updated_at.present?
  end

  def entry_changed?
    return false if entry_id.blank? || base_entry_updated_at.blank?

    entry = Entry.find_by(id: entry_id)
    return false unless entry

    entry.updated_at.to_i != base_entry_updated_at.to_i
  end

  def new_entry_draft?
    entry_id.blank? && base_entry_updated_at.blank?
  end

  def display_title
    title.presence || "Untitled"
  end

  def kind_label
    if orphaned_edit?
      "Edit (original Entry missing)"
    elsif entry_id.present?
      "Edit Entry"
    else
      "New Entry"
    end
  end

  def apply_expected_lock_version!(expected)
    return if expected.nil?

    self.lock_version = expected.to_i
  end

  def conflict_payload(edit_url: nil)
    {
      error: "conflict",
      id: id,
      lock_version: lock_version,
      title: title,
      raw_date: raw_date,
      body_markdown: body_markdown.to_s,
      content_updated_at: content_updated_at&.iso8601(3),
      client_create_id: client_create_id,
      edit_url: edit_url
    }.compact
  end

  private

  def ensure_content_updated_at
    self.content_updated_at ||= Time.current
  end

  def normalize_person_selections
    self.person_selections = person_selections_hash
  end

  def capture_base_entry_timestamp
    return if entry_id.blank?
    return if base_entry_updated_at.present?

    entry = Entry.find_by(id: entry_id)
    self.base_entry_updated_at = entry&.updated_at
  end

  def stringify_selections(value)
    case value
    when Hash
      value.stringify_keys.transform_values { |v| v.nil? ? nil : v.to_s }
    when String
      JSON.parse(value.presence || "{}").stringify_keys
    else
      {}
    end
  rescue JSON::ParserError
    {}
  end
end
