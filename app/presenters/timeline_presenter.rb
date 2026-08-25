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

  def self.parse_year(raw, today: Time.zone.today)
    year = Integer(raw, exception: false)
    return fallback_year(today: today) unless year&.between?(MIN_YEAR, MAX_YEAR)

    year
  end

  def self.fallback_year(today: Time.zone.today)
    today.year
  end

  def self.show_all?(raw)
    value = raw.to_s
    value.present? && value != "0"
  end

  def initialize(year:, today: Time.zone.today, available_years: nil, show_all: false)
    @year = year
    @today = today
    @available_years = available_years
    @show_all = show_all
  end

  attr_reader :year

  def show_all?
    @show_all
  end

  def query_params
    show_all? ? { show_all: 1 } : {}
  end

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

  def current_year?
    @year == @today.year
  end

  def visible_dates
    return dates if show_all?

    dates_with_entries = entries_by_date.keys.sort
    return dates_with_entries unless current_year?
    return dates_with_entries if dates_with_entries.include?(@today)

    (dates_with_entries + [ @today ]).sort
  end

  def empty_filtered_state?
    !show_all? && visible_dates.empty?
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
