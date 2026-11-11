module GoogleCalendar
  # Fetches allowlisted calendars for the two-week window and returns day-grouped events.
  class EventsQuery
    Result = Data.define(:status, :events_by_date, :message)

    def initialize(client: Client.new, range: WeekRange.for)
      @client = client
      @range = range
    end

    def call
      oauth_status = Oauth.status
      # #region agent log
      DebugLog.log("D", "events_query.rb:call", "EventsQuery start", {
        oauthStatus: oauth_status.to_s,
        rangeStart: @range.start_date.iso8601,
        rangeEnd: @range.end_date.iso8601
      })
      # #endregion

      case oauth_status
      when :not_configured
        return Result.new(status: :unavailable, events_by_date: {}, message: "Google Calendar is not configured.")
      when :disconnected
        return Result.new(status: :disconnected, events_by_date: {}, message: "Connect Google Calendar in Config.")
      when :reconnect_required
        return Result.new(status: :reconnect_required, events_by_date: {}, message: "Reconnect Google Calendar in Config.")
      end

      allowlist = Setting.google_calendar_allowlist
      if allowlist.empty?
        # #region agent log
        DebugLog.log("D", "events_query.rb:call", "empty allowlist", { allowlistCount: 0 })
        # #endregion
        return Result.new(
          status: :empty_allowlist,
          events_by_date: empty_days,
          message: "Select calendars in Config."
        )
      end

      # #region agent log
      DebugLog.log("B", "events_query.rb:call", "fetching allowlisted calendars", { allowlistCount: allowlist.size, allowlist: allowlist.map { |id| id.to_s[0, 64] } })
      # #endregion
      events = fetch_normalized(allowlist)
      grouped = EventAggregator.group_by_date(events, range: @range)
      # #region agent log
      DebugLog.log("B", "events_query.rb:call", "fetch ok", { eventCount: events.size, dayCount: grouped.keys.size })
      # #endregion
      Result.new(status: :ok, events_by_date: empty_days.merge(grouped), message: nil)
    rescue Oauth::ReauthorizationRequired => e
      # #region agent log
      DebugLog.log("A", "events_query.rb:call", "reauthorization required during query", { errorClass: e.class.name, errorMessage: e.message.to_s[0, 300] })
      # #endregion
      Result.new(status: :reconnect_required, events_by_date: {}, message: "Reconnect Google Calendar in Config.")
    rescue StandardError => e
      # #region agent log
      DebugLog.log("A-B", "events_query.rb:call", "events fetch failed -> temporarily unavailable", {
        errorClass: e.class.name,
        errorMessage: e.message.to_s[0, 400],
        backtrace0: e.backtrace&.first,
        backtrace1: e.backtrace&.[](1)
      })
      # #endregion
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
          "date" => item.start&.date&.to_s,
          "dateTime" => item.start&.date_time&.iso8601
        },
        "end" => {
          "date" => item.end&.date&.to_s,
          "dateTime" => item.end&.date_time&.iso8601
        }
      }
    end
  end
end
