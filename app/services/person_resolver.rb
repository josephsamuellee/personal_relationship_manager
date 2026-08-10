class PersonResolver
  Result = Struct.new(:status, :people, :query, keyword_init: true) do
    def exact? = status == :exact
    def ambiguous? = status == :ambiguous
    def unknown? = status == :unknown
  end

  def self.resolve(name)
    new.resolve(name)
  end

  def resolve(name)
    query = name.to_s.strip
    return Result.new(status: :unknown, people: [], query: query) if query.blank?

    exact = Person.where("LOWER(name) = ?", query.downcase).order(:name).to_a
    return Result.new(status: :exact, people: [exact.first], query: query) if exact.size == 1
    return Result.new(status: :ambiguous, people: exact, query: query) if exact.size > 1

    prefix = Person.where("LOWER(name) LIKE ?", "#{query.downcase}%").order(:name).to_a
    return Result.new(status: :exact, people: [prefix.first], query: query) if prefix.size == 1
    return Result.new(status: :ambiguous, people: prefix, query: query) if prefix.size > 1

    substring = Person.where("LOWER(name) LIKE ?", "%#{query.downcase}%").order(:name).to_a
    return Result.new(status: :exact, people: [substring.first], query: query) if substring.size == 1
    return Result.new(status: :ambiguous, people: substring, query: query) if substring.size > 1

    Result.new(status: :unknown, people: [], query: query)
  end
end
