module TimelineHelper
  def timeline_calendar_date(date, label:)
    link_to label,
            new_entry_path_for_date(date),
            class: "year-timeline-cal year-timeline-cal-link",
            role: "cell",
            aria: { label: "New entry for #{date.strftime("%A, %-d %b %Y")}" }
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
