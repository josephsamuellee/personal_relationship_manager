module GoogleCalendar
  # In-memory normalized external calendar event (not persisted).
  class Event
    attr_reader :provider, :external_id, :calendar_id, :title, :starts_at, :ends_at, :all_day

    def initialize(provider:, external_id:, calendar_id:, title:, starts_at:, ends_at:, all_day:)
      @provider = provider
      @external_id = external_id.to_s
      @calendar_id = calendar_id.to_s
      @title = title.to_s
      @starts_at = starts_at
      @ends_at = ends_at
      @all_day = all_day
    end

    def all_day?
      !!@all_day
    end

    def identity_key
      "#{provider}:#{external_id}"
    end

    # Local calendar dates this event should appear on within the application time zone.
    def local_dates
      if all_day?
        all_day_dates
      else
        timed_dates
      end
    end

    private

    def all_day_dates
      start_date = coerce_date(starts_at)
      exclusive_end = coerce_date(ends_at)
      return [ start_date ] if exclusive_end <= start_date

      (start_date...exclusive_end).to_a
    end

    def timed_dates
      start_time = coerce_time(starts_at)
      end_time = coerce_time(ends_at)
      end_time = start_time if end_time < start_time

      # Instantaneous or zero-length: single local date.
      if end_time == start_time
        return [ start_time.to_date ]
      end

      # Inclusive of start date; exclusive of end when end is exactly midnight
      # (interval ended at the boundary of that day).
      first = start_time.to_date
      last = end_time.to_date
      last -= 1 if end_time == end_time.beginning_of_day && last > first

      (first..last).to_a
    end

    def coerce_date(value)
      case value
      when Date then value
      when Time, ActiveSupport::TimeWithZone then value.in_time_zone(Time.zone).to_date
      else Date.iso8601(value.to_s)
      end
    end

    def coerce_time(value)
      case value
      when ActiveSupport::TimeWithZone, Time
        value.in_time_zone(Time.zone)
      when Date
        Time.zone.local(value.year, value.month, value.day)
      else
        Time.zone.parse(value.to_s)
      end
    end
  end
end
