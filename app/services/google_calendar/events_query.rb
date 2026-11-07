module GoogleCalendar
  # Fetches allowlisted calendars for the two-week window and returns day-grouped events.
  class EventsQuery
    Result = Data.define(:status, :events_by_date, :message)

    def initialize(client: Client.new, range: WeekRange.for)
      @client = client
      @range = range
    end

    def call
      case Oauth.status
      when :not_configured
        return Result.new(status: :unavailable, events_by_date: {}, message: "Google Calendar is not configured.")
      when :disconnected
        return Result.new(status: :disconnected, events_by_date: {}, message: "Connect Google Calendar in Config.")
      when :reconnect_required
        return Result.new(status: :reconnect_required, events_by_date: {}, message: "Reconnect Google Calendar in Config.")
      end

      allowlist = Setting.google_calendar_allowlist
      if allowlist.empty?
        return Result.new(
          status: :empty_allowlist,
          events_by_date: empty_days,
          message: "Select calendars in Config."
        )
      end

      events = fetch_normalized(allowlist)
      grouped = EventAggregator.group_by_date(events, range: @range)
      Result.new(status: :ok, events_by_date: empty_days.merge(grouped), message: nil)
    rescue Oauth::ReauthorizationRequired
      Result.new(status: :reconnect_required, events_by_date: {}, message: "Reconnect Google Calendar in Config.")
    rescue StandardError => e
      Rails.logger.warn("[GoogleCalendar] events fetch failed: #{e.class}")
      Result.new(status: :error, events_by_date: {}, message: "Google Calendar is temporarily unavailable.")
    end

    private

    def empty_days
      @range.weeks.flat_map(&:dates).index_with { [] }
    end

    def fetch_normalized(allowlist)
      time_min = Time.zone.local(@range.start_date.year, @range.start_date.month, @range.start_date.day).beginning_of_day
      time_max = Time.zone.local(@range.end_date.year, @range.end_date.month, @range.end_date.day).end_of_day

      allowlist.flat_map do |calendar_id|
        @client.list_events(calendar_id: calendar_id, time_min: time_min, time_max: time_max).filter_map do |item|
          hash = api_item_to_hash(item)
          EventNormalizer.from_api(hash, calendar_id: calendar_id)
        end
      end
    end

    def api_item_to_hash(item)
      {
        "id" => item.id,
        "status" => item.status,
        "summary" => item.summary,
        "start" => {
          "date" => item.start&.date,
          "dateTime" => item.start&.date_time&.iso8601
        },
        "end" => {
          "date" => item.end&.date,
          "dateTime" => item.end&.date_time&.iso8601
        }
      }
    end
  end
end
