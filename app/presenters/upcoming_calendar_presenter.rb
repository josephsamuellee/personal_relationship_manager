class UpcomingCalendarPresenter
  def initialize(today: Time.zone.today)
    @today = today.to_date
    @range = GoogleCalendar::WeekRange.for(@today)
  end

  def weeks
    @range.weeks
  end

  def today?(date)
    date == @today
  end

  def day_label(date)
    format("%02d", date.day)
  end

  def weekday_headers
    %w[Mon Tue Wed Thu Fri Sat Sun]
  end
end
