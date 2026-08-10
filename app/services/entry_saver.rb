class EntrySaver
  def self.save!(draft)
    new(draft).save!
  end

  def initialize(draft)
    @draft = draft
  end

  def save!
    raise ArgumentError, "Draft is not valid for save" unless @draft.valid_for_save?

    Entry.transaction do
      entry = find_or_build_entry
      entry.assign_attributes(
        title: @draft.title,
        occurred_on: @draft.occurred_on,
        body_markdown: @draft.body_markdown
      )

      entry.entry_people.destroy_all if entry.persisted?
      @draft.resolved_people.each_with_index do |person, index|
        entry.entry_people.build(person: person, position: index)
      end

      entry.primary_person = @draft.primary_person
      entry.save!

      sync_entry_tags!(entry)
      entry
    end
  end

  private

  def find_or_build_entry
    if @draft.entry_id.present?
      Entry.find(@draft.entry_id)
    else
      Entry.new
    end
  end

  def sync_entry_tags!(entry)
    entry.entry_tags.destroy_all
    @draft.parsed_tags.each do |tag_name|
      tag = Tag.find_or_create_by_normalized!(tag_name)
      entry.entry_tags.create!(tag: tag)
    end
  end
end
