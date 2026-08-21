class Setting < ApplicationRecord
  THEMES = %w[dark light].freeze
  DEFAULT_THEME = "dark".freeze
  FAVORITE_SLOTS = [ 1, 2, 3 ].freeze
  FAVORITE_COLUMNS = {
    1 => :favorite_person_1_id,
    2 => :favorite_person_2_id,
    3 => :favorite_person_3_id
  }.freeze

  validates :theme, inclusion: { in: THEMES }

  def self.current_theme
    value = first&.theme
    THEMES.include?(value) ? value : DEFAULT_THEME
  end

  def self.update_theme(value)
    normalized = value.to_s
    return current_theme unless THEMES.include?(normalized)

    record = first_or_initialize
    record.theme = normalized
    record.save!
    record.theme
  end

  def self.favorite_person_ids
    record = first
    return [ nil, nil, nil ] unless record

    FAVORITE_SLOTS.map { |slot| record.public_send(FAVORITE_COLUMNS[slot]) }
  end

  # Returns [Person|nil, Person|nil, Person|nil] for slots 1–3.
  # Stale IDs (deleted people) are treated as empty and cleared from settings.
  def self.favorite_people
    ids = favorite_person_ids
    people_by_id = Person.where(id: ids.compact).index_by(&:id)
    result = ids.map { |id| id.nil? ? nil : people_by_id[id] }

    if ids.zip(result).any? { |id, person| id.present? && person.nil? }
      clear_stale_favorite_ids!(ids, people_by_id)
    end

    result
  end

  def self.favorite_slot_for(person)
    return nil unless person&.id

    index = favorite_person_ids.index(person.id)
    index && index + 1
  end

  # Assigns person to slot (1, 2, or 3) or clears them when slot is blank/"Not favorited".
  # Replaces any previous occupant of the target slot and clears the person's prior slot.
  def self.assign_favorite_slot!(person, slot)
    raise ArgumentError, "person is required" unless person&.id

    normalized = normalize_favorite_slot(slot)

    transaction do
      record = lock_settings_row!
      clear_person_from_favorites!(record, person.id)

      if normalized
        record.public_send("#{FAVORITE_COLUMNS[normalized]}=", person.id)
      end

      record.save!
    end
  end

  def self.normalize_favorite_slot(slot)
    return nil if slot.nil? || slot.to_s.strip.empty?

    value = Integer(slot, exception: false)
    return value if FAVORITE_SLOTS.include?(value)

    raise ArgumentError, "invalid favorite slot: #{slot.inspect}"
  end

  def self.lock_settings_row!
    record = first_or_initialize
    record.theme = DEFAULT_THEME if record.theme.blank?
    record.save! if record.new_record?
    record.lock!
    record
  end
  private_class_method :lock_settings_row!

  def self.clear_person_from_favorites!(record, person_id)
    FAVORITE_COLUMNS.each_value do |column|
      record.public_send("#{column}=", nil) if record.public_send(column) == person_id
    end
  end
  private_class_method :clear_person_from_favorites!

  def self.clear_stale_favorite_ids!(ids, people_by_id)
    record = first
    return unless record

    FAVORITE_SLOTS.each_with_index do |slot, index|
      id = ids[index]
      next if id.nil? || people_by_id[id]

      record.public_send("#{FAVORITE_COLUMNS[slot]}=", nil)
    end
    record.save!
  end
  private_class_method :clear_stale_favorite_ids!
end
