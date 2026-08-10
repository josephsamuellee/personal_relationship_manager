class EntryRelationshipDiff
  Change = Struct.new(:primary_from, :primary_to, :added, :removed, keyword_init: true)

  def initialize(entry, draft)
    @entry = entry
    @draft = draft
  end

  def changes
    old_people = @entry.people.order(:name).pluck(:name, :id).to_h
    new_people = @draft.resolved_people.index_by(&:name)

    Change.new(
      primary_from: @entry.primary_person&.name,
      primary_to: @draft.primary_person&.name,
      added: new_people.keys - old_people.keys,
      removed: old_people.keys - new_people.keys
    )
  end

  def changed?
    c = changes
    c.primary_from != c.primary_to || c.added.any? || c.removed.any?
  end
end
