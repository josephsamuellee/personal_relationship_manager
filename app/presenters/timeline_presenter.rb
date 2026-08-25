class TimelinePresenter
  MIN_YEAR = 1
  MAX_YEAR = 9999

  def self.available_years
    Entry.distinct
         .order(:occurred_on)
         .pluck(:occurred_on)
         .map(&:year)
         .uniq
  end

  def self.parse_year(raw, today: Time.zone.today, available: nil)
    years = available || available_years
    year = Integer(raw, exception: false)
    return fallback_year(today: today) unless year&.between?(MIN_YEAR, MAX_YEAR)
    return year if years.include?(year)
    return year if year == today.year

    fallback_year(today: today)
  end

  def self.fallback_year(today: Time.zone.today)
    today.year
  end

  def initialize(year:, today: Time.zone.today, available_years: nil)
    @year = year
    @today = today
    @available_years = available_years
  end

  attr_reader :year

  def available_years
    @available_years ||= self.class.available_years
  end

  def start_date
    Date.new(@year, 1, 1)
  end

  def end_date
    Date.new(@year, 12, 31)
  end

  def dates
    (start_date..end_date).to_a
  end

  def entries_by_date
    @entries_by_date ||= begin
      Entry.includes(:primary_person)
           .between_dates(start_date, end_date)
           .order(:occurred_on, :title)
           .group_by(&:occurred_on)
    end
  end

  def entries_for(date)
    entries_by_date[date] || []
  end

  def previous_year
    available_years.reverse.find { |y| y < @year }
  end

  def next_year
    available_years.find { |y| y > @year }
  end

  def iso_week_day_label(date)
    format("W%02d-%d", date.cweek, date.cwday)
  end

  def calendar_date_label(date)
    date.strftime("%d%b")
  end

  def today?(date)
    date == @today
  end
end
