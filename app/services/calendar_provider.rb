class CalendarProvider
  def self.current
    EmbedCalendarProvider.new
  end
end

class EmbedCalendarProvider
  def available?
    embed_url.present?
  end

  def embed_url
    ENV["GOOGLE_CALENDAR_EMBED_URL"].presence
  end
end
