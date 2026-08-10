class Entry < ApplicationRecord
  belongs_to :primary_person, class_name: "Person"
  has_many :entry_people, -> { order(:position) }, dependent: :destroy, inverse_of: :entry
  has_many :people, through: :entry_people
  has_many :entry_tags, dependent: :destroy
  has_many :tags, through: :entry_tags

  validates :title, :occurred_on, :body_markdown, presence: true
  validate :primary_person_in_people

  scope :on_date, ->(date) { where(occurred_on: date) }
  scope :between_dates, ->(start_date, end_date) { where(occurred_on: start_date..end_date) }
  scope :recent_first, -> { order(occurred_on: :desc, created_at: :desc) }
  scope :chronological, -> { order(occurred_on: :asc, created_at: :asc) }

  def secondary_people
    people.where.not(id: primary_person_id)
  end

  def primary_for?(person)
    primary_person_id == person.id
  end

  private

  def primary_person_in_people
    return if primary_person_id.blank?
    return if entry_people.empty?

    unless entry_people.any? { |ep| ep.person_id == primary_person_id }
      errors.add(:primary_person, "must be one of the associated people")
    end
  end
end
