module TimelineHelper
  # Renders the compact calendar date label. Kept separate so a future change can
  # turn this into a link that opens New Journal with occurred_on pre-filled.
  def timeline_calendar_date(date, label:)
    tag.span(label, class: "year-timeline-cal", role: "cell", data: { occurred_on: date.iso8601 })
  end

  def timeline_year_path(year, presenter)
    timeline_path({ year: year }.merge(presenter.query_params))
  end

  def timeline_jump_to_today_path(presenter)
    timeline_path(
      { year: Time.zone.today.year }.merge(presenter.query_params).merge(anchor: "today")
    )
  end
end
