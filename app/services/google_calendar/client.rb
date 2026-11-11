require "google/apis/calendar_v3"

module GoogleCalendar
  class Client
    CalendarInfo = Data.define(:id, :summary, :primary)

    def initialize(oauth: Oauth.new)
      @oauth = oauth
    end

    def list_calendars
      service = calendar_service
      items = []
      page_token = nil
      loop do
        response = service.list_calendar_lists(page_token: page_token, min_access_role: "reader")
        Array(response.items).each do |item|
          items << CalendarInfo.new(
            id: item.id,
            summary: item.summary.presence || item.id,
            primary: !!item.primary
          )
        end
        page_token = response.next_page_token
        break if page_token.blank?
      end
      items.sort_by { |c| [ c.primary ? 0 : 1, c.summary.downcase ] }
    end

    def list_events(calendar_id:, time_min:, time_max:)
      service = calendar_service
      items = []
      page_token = nil
      loop do
        response = service.list_events(
          calendar_id,
          single_events: true,
          order_by: "startTime",
          time_min: time_min.iso8601,
          time_max: time_max.iso8601,
          page_token: page_token,
          fields: "items(id,status,summary,start,end),nextPageToken"
        )
        items.concat(Array(response.items))
        page_token = response.next_page_token
        break if page_token.blank?
      end
      items
    end

    private

    def calendar_service
      service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = @oauth.credentials
      service.client_options.application_name = "PRM Upcoming Calendar"
      service
    end
  end
end
