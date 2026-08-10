class SearchService
  MAX_RESULTS = 3

  def initialize(query)
    @query = query.to_s.strip
  end

  def results
    {
      people: search_people,
      timeline: search_timeline,
      entries: search_entries
    }
  end

  private

  def search_people
    return [] if @query.blank?

    exact = Person.where("LOWER(name) = ?", @query.downcase).limit(MAX_RESULTS).to_a
    return exact if exact.size >= MAX_RESULTS

    prefix = Person.where("LOWER(name) LIKE ?", "#{@query.downcase}%")
                   .where.not(id: exact.map(&:id))
                   .order(:name)
                   .limit(MAX_RESULTS - exact.size)
                   .to_a
    combined = exact + prefix
    return combined if combined.size >= MAX_RESULTS

    substring = Person.where("LOWER(name) LIKE ?", "%#{@query.downcase}%")
                      .where.not(id: combined.map(&:id))
                      .order(:name)
                      .limit(MAX_RESULTS - combined.size)
                      .to_a
    combined + substring
  end

  def search_timeline
    date = DateParser.parse(@query)
    on_date = Entry.includes(:primary_person).on_date(date).recent_first.limit(MAX_RESULTS).to_a
    return on_date if on_date.size >= MAX_RESULTS

    remaining = MAX_RESULTS - on_date.size
    nearest = Entry.includes(:primary_person)
                   .where.not(id: on_date.map(&:id))
                   .order(Arel.sql("ABS(julianday(occurred_on) - julianday('#{date.iso8601}'))"))
                   .limit(remaining)
                   .to_a
    on_date + nearest
  rescue DateParser::ParseError
    []
  end

  def search_entries
    return [] if @query.blank?

    like = "%#{@query.downcase}%"
    title_matches = Entry.includes(:primary_person, :tags)
                         .where("LOWER(title) LIKE ?", like)
                         .recent_first
                         .limit(MAX_RESULTS)
                         .to_a
    return title_matches if title_matches.size >= MAX_RESULTS

    tag_matches = Entry.includes(:primary_person, :tags)
                       .joins(:tags)
                       .where("LOWER(tags.name) LIKE ?", like)
                       .where.not(id: title_matches.map(&:id))
                       .recent_first
                       .limit(MAX_RESULTS - title_matches.size)
                       .to_a
    combined = title_matches + tag_matches
    return combined if combined.size >= MAX_RESULTS

    body_matches = Entry.includes(:primary_person, :tags)
                        .where("LOWER(body_markdown) LIKE ?", like)
                        .where.not(id: combined.map(&:id))
                        .recent_first
                        .limit(MAX_RESULTS - combined.size)
                        .to_a
    combined + body_matches
  end
end
