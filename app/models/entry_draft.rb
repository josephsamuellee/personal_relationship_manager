class EntryDraft
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :title, :string
  attribute :raw_date, :string
  attribute :occurred_on, :date
  attribute :body_markdown, :string
  attribute :entry_id, :integer
  attribute :parsed_people, default: -> { [] }
  attribute :resolved_people_ids, default: -> { [] }
  attribute :parsed_tags, default: -> { [] }
  attribute :person_selections, default: -> { {} }
  attribute :validation_errors, default: -> { [] }

  def self.from_params(params)
    draft = new(
      title: params[:title],
      raw_date: params[:raw_date] || params[:occurred_on],
      body_markdown: params[:body_markdown],
      entry_id: params[:entry_id],
      person_selections: params[:person_selections] || {}
    )
    draft.parse!
    draft
  end

  def self.from_session(data)
    attrs = data.symbolize_keys
    attrs[:occurred_on] = Date.parse(attrs[:occurred_on]) if attrs[:occurred_on].is_a?(String)
    draft = new(attrs)
    draft.parse!
    draft
  end

  def to_session
    {
      title: title,
      raw_date: raw_date,
      occurred_on: occurred_on&.iso8601,
      body_markdown: body_markdown,
      entry_id: entry_id,
      parsed_people: parsed_people,
      resolved_people_ids: resolved_people_ids,
      parsed_tags: parsed_tags,
      person_selections: person_selections,
      validation_errors: validation_errors
    }
  end

  def parse!
    self.validation_errors = []
    self.parsed_people = WikiPersonParser.parse(body_markdown)
    self.parsed_tags = TagParser.parse(body_markdown)

    parse_date!
    resolve_people!
    validate!
    self
  end

  def resolved_people
    resolved_people_ids.filter_map { |id| Person.find_by(id: id) }
  end

  def primary_person
    resolved_people.first
  end

  def secondary_people
    resolved_people.drop(1)
  end

  def unresolved_people
    selections = (person_selections || {}).stringify_keys
    parsed_people.each_with_index.filter_map do |name, index|
      next if resolved_people_ids[index].present?

      result = PersonResolver.resolve(selections[name] || name)
      { name: name, index: index, result: result }
    end
  end

  def valid_for_save?
    validation_errors.empty? && unresolved_people.empty? && parsed_people.any? && occurred_on.present?
  end

  def relationship_changes_for(entry)
    EntryRelationshipDiff.new(entry, self).changes
  end

  private

  def parse_date!
    self.occurred_on = DateParser.parse(raw_date)
  rescue DateParser::ParseError => e
    validation_errors << e.message
    self.occurred_on = nil
  end

  def resolve_people!
    ids = []
    selections = (person_selections || {}).stringify_keys
    parsed_people.each_with_index do |name, _index|
      if selections[name].present?
        person = Person.find_by(id: selections[name])
        ids << person&.id
        next
      end

      result = PersonResolver.resolve(name)
      case result.status
      when :exact
        ids << result.people.first.id
      when :ambiguous, :unknown
        ids << nil
      end
    end
    self.resolved_people_ids = ids
  end

  def validate!
    validation_errors << "An entry must contain at least one person link such as [[Andrew]]." if parsed_people.empty?
    validation_errors << "Title cannot be blank." if title.blank?
    validation_errors << "Date cannot be blank." if raw_date.blank? && occurred_on.blank?
  end
end
