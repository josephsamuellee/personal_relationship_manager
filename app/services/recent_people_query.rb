# Returns unique People ranked by their most recent saved Entry association.
class RecentPeopleQuery
  LIMIT = 20

  def self.call(limit: LIMIT)
    new(limit: limit).call
  end

  def initialize(limit: LIMIT)
    @limit = limit
  end

  def call
    Person
      .joins(entry_people: :entry)
      .group("people.id")
      .order(Arel.sql("MAX(entries.occurred_on) DESC, MAX(entries.created_at) DESC, people.name ASC"))
      .limit(@limit)
      .to_a
  end
end
