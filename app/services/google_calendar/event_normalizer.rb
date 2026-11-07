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
        Date.iso8601(start_node["date"])
      else
        Time.zone.parse(start_node["dateTime"])
      end
    end

    def ends_at
      if all_day?
        raw = end_node["date"]
        raw.present? ? Date.iso8601(raw) : starts_at + 1
      else
        raw = end_node["dateTime"]
        raw.present? ? Time.zone.parse(raw) : starts_at
      end
    end

    # Prefer recurring instance id when present; otherwise event id.
    def reliable_external_id
      @item["id"].to_s
    end
  end
end
