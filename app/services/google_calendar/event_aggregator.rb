module GoogleCalendar
  # Filters, dedupes, and groups normalized events by local date.
  class EventAggregator
    def self.group_by_date(events, range:)
      new(events, range: range).group_by_date
    end

    def initialize(events, range:)
      @events = Array(events).compact
      @range = range
    end

    def group_by_date
      deduped = dedupe(@events)
      grouped = Hash.new { |h, k| h[k] = [] }

      deduped.each do |event|
        event.local_dates.each do |date|
          next unless @range.include?(date)

          grouped[date] << event
        end
      end

      grouped.each_value { |list| list.sort_by! { |e| [ e.all_day? ? 0 : 1, e.starts_at.to_s, e.title ] } }
      grouped
    end

    def self.dedupe(events)
      new(events, range: nil).send(:dedupe, events)
    end

    private

    def dedupe(events)
      seen = {}
      events.each_with_object([]) do |event, kept|
        key = event.identity_key
        next if seen[key]

        seen[key] = true
        kept << event
      end
    end
  end
end
