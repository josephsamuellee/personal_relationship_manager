class DateParser
  class ParseError < StandardError
    attr_reader :message

    def initialize(message)
      @message = message
      super(message)
    end
  end

  AMBIGUOUS_SLASH = %r{\A\d{1,2}/\d{1,2}/\d{2,4}\z}.freeze
  FORMATS = [
    { regex: /\A(\d{2})[ -]([A-Za-z]{3})[ -](\d{4})\z/, parser: :parse_dmy_month_name },
    { regex: /\A(\d{4})(\d{2})(\d{2})\z/, parser: :parse_yyyymmdd },
    { regex: /\A(\d{4})-(\d{2})-(\d{2})\z/, parser: :parse_iso_date },
    { regex: /\A(\d{4})-W(\d{2})-(\d)\z/i, parser: :parse_iso_week }
  ].freeze

  MONTHS = {
    "jan" => 1, "feb" => 2, "mar" => 3, "apr" => 4, "may" => 5, "jun" => 6,
    "jul" => 7, "aug" => 8, "sep" => 9, "oct" => 10, "nov" => 11, "dec" => 12
  }.freeze

  def self.parse(input)
    new.parse(input)
  end

  def parse(input)
    text = input.to_s.strip
    raise ParseError, "Date cannot be blank" if text.blank?
    raise ParseError, ambiguous_message(text) if text.match?(AMBIGUOUS_SLASH)

    FORMATS.each do |format|
      next unless (match = text.match(format[:regex]))

      return send(format[:parser], match)
    end

    raise ParseError, "\"#{text}\" is not a recognized date format"
  end

  private

  def ambiguous_message(text)
    "\"#{text}\" is ambiguous. Use a format such as: 09 Aug 2026, 09-Aug-2026, 2026-08-09, 20260809, 2026-W32-7"
  end

  def parse_dmy_month_name(match)
    day, month_name, year = match.captures
    month = MONTHS[month_name.downcase[0, 3]]
    raise ParseError, "Invalid month name" unless month

    build_date(year.to_i, month, day.to_i)
  end

  def parse_yyyymmdd(match)
    year, month, day = match.captures.map(&:to_i)
    build_date(year, month, day)
  end

  def parse_iso_date(match)
    year, month, day = match.captures.map(&:to_i)
    build_date(year, month, day)
  end

  def parse_iso_week(match)
    year, week, day = match.captures
    Date.commercial(year.to_i, week.to_i, day.to_i)
  rescue ArgumentError
    raise ParseError, "Invalid ISO week date"
  end

  def build_date(year, month, day)
    Date.new(year, month, day)
  rescue ArgumentError
    raise ParseError, "Invalid date"
  end
end
