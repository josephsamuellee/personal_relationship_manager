class PersonResolver
  SUGGESTION_PREFIX_LENGTH = 3

  Result = Struct.new(:status, :people, :query, keyword_init: true) do
    def exact? = status == :exact
    def ambiguous? = status == :ambiguous
    def unknown? = status == :unknown
  end

  def self.resolve(name)
    new.resolve(name)
  end

  def self.suggest(name)
    new.suggest(name)
  end

  def resolve(name)
    query = name.to_s.strip
    return Result.new(status: :unknown, people: [], query: query) if query.blank?

    exact = Person.where("LOWER(name) = ?", query.downcase).order(:name).to_a
    return Result.new(status: :exact, people: [exact.first], query: query) if exact.size == 1
    return Result.new(status: :ambiguous, people: exact, query: query) if exact.size > 1

    Result.new(status: :unknown, people: [], query: query)
  end

  def suggest(name)
    query = name.to_s.strip
    return [] if query.blank?

    prefix = query.downcase[0, SUGGESTION_PREFIX_LENGTH]
    return [] if prefix.blank?

    suggestions = Person.where("LOWER(name) LIKE ?", "#{prefix}%")
                      .where.not("LOWER(name) = ?", query.downcase)
                      .order(:name)
                      .to_a

    suggestions
  end
end
