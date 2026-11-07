class UpcomingCalendarEventsController < ApplicationController
  def show
    result = GoogleCalendar::EventsQuery.new.call
    payload = {
      status: result.status,
      message: result.message,
      events_by_date: serialize_events(result.events_by_date)
    }
    render json: payload
  end

  private

  def serialize_events(events_by_date)
    events_by_date.transform_keys(&:iso8601).transform_values do |events|
      Array(events).map do |event|
        {
          id: event.external_id,
          title: event.title,
          all_day: event.all_day?
        }
      end
    end
  end
end
