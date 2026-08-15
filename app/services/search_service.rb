class SearchService
  MAX_RESULTS = 3

  def initialize(query)
    @query = query.to_s.strip
  end

  def results
    preview_entries, more_entries = truncated_entries

    {
      people: search_people,
      timeline: search_timeline,
      entries: preview_entries,
      more_entries: more_entries
    }
  end

  def all_entries
    matching_entries
      .includes(:primary_person, entry_people: :person)
      .recent_first
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

  def truncated_entries
    records = matching_entries
                .includes(:primary_person, :tags)
                .recent_first
                .limit(MAX_RESULTS + 1)
                .to_a

    [records.first(MAX_RESULTS), records.size > MAX_RESULTS]
  end

  def matching_entries
    return Entry.none if @query.blank?

    like = "%#{@query.downcase}%"
    Entry.where(
      <<~SQL.squish,
        LOWER(title) LIKE :q
        OR LOWER(body_markdown) LIKE :q
        OR EXISTS (
          SELECT 1
          FROM entry_tags
          INNER JOIN tags ON tags.id = entry_tags.tag_id
          WHERE entry_tags.entry_id = entries.id
            AND LOWER(tags.name) LIKE :q
        )
      SQL
      q: like
    )
  end
end
