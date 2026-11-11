module GoogleCalendar
  # Two complete ISO-8601 weeks: the week containing +today+, then the next week.
  class WeekRange
    Week = Data.define(:iso_week_year, :iso_week, :label, :dates)

    def self.for(today = Time.zone.today)
      new(today)
    end

    def initialize(today)
      @today = today.to_date
    end

    def weeks
      [ week_for(@today), week_for(@today + 7) ]
    end

    def start_date
      weeks.first.dates.first
    end

    def end_date
      weeks.last.dates.last
    end

    def include?(date)
      date = date.to_date
      date >= start_date && date <= end_date
    end

    private

    def week_for(date)
      monday = date.beginning_of_week(:monday)
      dates = (0..6).map { |offset| monday + offset }
      Week.new(
        iso_week_year: monday.cwyear,
        iso_week: monday.cweek,
        label: format("W%02d", monday.cweek),
        dates: dates
      )
    end
  end
end
