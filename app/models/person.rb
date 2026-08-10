class Person < ApplicationRecord
  has_many :entry_people, dependent: :destroy
  has_many :entries, through: :entry_people
  has_many :primary_entries, class_name: "Entry", foreign_key: :primary_person_id, inverse_of: :primary_person

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug

  scope :ordered_by_name, -> { order(:name) }

  def self.find_by_name_or_slug(identifier)
    find_by(slug: identifier.to_s.parameterize) || find_by(name: identifier)
  end

  private

  def generate_slug
    self.slug = name.to_s.parameterize if name.present?
  end
end
