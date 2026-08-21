class HomepagePresenter
  LANDSCAPE_OLDER_COUNT = 7

  def initialize(today: Time.zone.today)
    @today = today
  end

  def recent_timeline_dates
    start_date = @today - 14.days
    (start_date..@today).to_a
  end

  def recent_timeline_older_dates
    recent_timeline_dates.first(LANDSCAPE_OLDER_COUNT)
  end

  def recent_timeline_newer_dates
    recent_timeline_dates.drop(LANDSCAPE_OLDER_COUNT)
  end

  def recent_timeline_entries
    @recent_timeline_entries ||= begin
      Entry.includes(:primary_person)
           .between_dates(recent_timeline_dates.first, recent_timeline_dates.last)
           .order(:occurred_on, :title)
           .group_by(&:occurred_on)
    end
  end

  def today?(date)
    date == @today
  end

  def week_label(date)
    return unless date.monday? || today?(date)

    format("W%02d", date.cweek)
  end

  def historical_window
  anchor = @today - 3.months
    {
      anchor: anchor,
      start_date: anchor - 7.days,
      end_date: anchor + 7.days
    }
  end

  def historical_entries
    window = historical_window
    Entry.includes(:primary_person, :people)
         .between_dates(window[:start_date], window[:end_date])
         .recent_first
  end

  def random_people
    Person.order(Arel.sql("RANDOM()")).limit(2)
  end

  def random_entries
    Entry.includes(:primary_person).order(Arel.sql("RANDOM()")).limit(2)
  end

  def weekday_letter(date)
    date.strftime("%a")[0]
  end

  # Ordered [slot1, slot2, slot3]; nil when unassigned or stale.
  def favorite_people
    @favorite_people ||= Setting.favorite_people
  end
end
