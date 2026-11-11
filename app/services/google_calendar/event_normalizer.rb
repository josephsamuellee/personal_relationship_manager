module GoogleCalendar
  # Turns raw Google Calendar API event hashes into Event value objects.
  class EventNormalizer
    PROVIDER = "google".freeze

    def self.from_api(item, calendar_id:)
      new(item, calendar_id: calendar_id).normalize
    end

    def initialize(item, calendar_id:)
      @item = item.respond_to?(:to_h) ? item.to_h.deep_stringify_keys : item
      @calendar_id = calendar_id
    end

    def normalize
      return nil if cancelled?
      return nil if title.blank?
      return nil unless start_present?

      Event.new(
        provider: PROVIDER,
        external_id: reliable_external_id,
        calendar_id: @calendar_id,
        title: title,
        starts_at: starts_at,
        ends_at: ends_at,
        all_day: all_day?
      )
    end

    private

    def cancelled?
      status = @item["status"].to_s
      status == "cancelled"
    end

    def title
      @item["summary"].to_s
    end

    def start_present?
      start_node.present?
    end

    def start_node
      @item["start"] || {}
    end

    def end_node
      @item["end"] || {}
    end

    def all_day?
      start_node["date"].present? && start_node["dateTime"].blank?
    end

    def starts_at
      if all_day?
        coerce_date(start_node["date"])
      else
        coerce_time(start_node["dateTime"])
      end
    end

    def ends_at
      if all_day?
        raw = end_node["date"]
        raw.present? ? coerce_date(raw) : starts_at + 1
      else
        raw = end_node["dateTime"]
        raw.present? ? coerce_time(raw) : starts_at
      end
    end

    # Google API client may yield Date/Time objects; stubbed hashes use strings.
    def coerce_date(value)
      case value
      when Date then value
      when Time, ActiveSupport::TimeWithZone then value.in_time_zone(Time.zone).to_date
      else Date.iso8601(value.to_s)
      end
    end

    def coerce_time(value)
      case value
      when ActiveSupport::TimeWithZone then value
      when Time then value.in_time_zone(Time.zone)
      when Date then Time.zone.local(value.year, value.month, value.day)
      else Time.zone.parse(value.to_s)
      end
    end

    # Prefer recurring instance id when present; otherwise event id.
    def reliable_external_id
      @item["id"].to_s
    end
  end
end
