require "test_helper"

class DateParserTest < ActiveSupport::TestCase
  test "parses DD MMM YYYY" do
    assert_equal Date.new(2026, 8, 9), DateParser.parse("09 Aug 2026")
  end

  test "parses DD-MMM-YYYY" do
    assert_equal Date.new(2026, 8, 9), DateParser.parse("09-Aug-2026")
  end

  test "parses YYYYMMDD" do
    assert_equal Date.new(2026, 8, 9), DateParser.parse("20260809")
  end

  test "parses ISO date" do
    assert_equal Date.new(2026, 8, 9), DateParser.parse("2026-08-09")
  end

  test "parses ISO week date" do
    assert_equal Date.new(2026, 8, 9), DateParser.parse("2026-W32-7")
  end

  test "rejects ambiguous slash dates" do
    assert_raises(DateParser::ParseError) { DateParser.parse("08/09/26") }
    assert_raises(DateParser::ParseError) { DateParser.parse("08/09/2026") }
    assert_raises(DateParser::ParseError) { DateParser.parse("9/8/26") }
  end

  test "rejects garbage" do
    assert_raises(DateParser::ParseError) { DateParser.parse("garbage") }
  end

  test "rejects invalid ISO week" do
    assert_raises(DateParser::ParseError) { DateParser.parse("2026-W99-7") }
  end
end
