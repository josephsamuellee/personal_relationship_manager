class Tag < ApplicationRecord
  has_many :entry_tags, dependent: :destroy
  has_many :entries, through: :entry_tags

  validates :name, presence: true, uniqueness: true

  before_validation :normalize_name

  def self.find_or_create_by_normalized!(name)
    normalized = TagParser.normalize(name)
    find_or_create_by!(name: normalized)
  end

  private

  def normalize_name
    self.name = TagParser.normalize(name) if name.present?
  end
end
