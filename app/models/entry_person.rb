class EntryPerson < ApplicationRecord
  belongs_to :entry
  belongs_to :person

  validates :position, presence: true
  validates :person_id, uniqueness: { scope: :entry_id }
end
