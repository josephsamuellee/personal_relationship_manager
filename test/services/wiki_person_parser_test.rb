require "test_helper"

class WikiPersonParserTest < ActiveSupport::TestCase
  test "parses single person" do
    assert_equal ["Andrew"], WikiPersonParser.parse("[[Andrew]]")
  end

  test "parses multiple people in order" do
    assert_equal ["Andrew", "Sarah"], WikiPersonParser.parse("[[Andrew]] and [[Sarah]]")
  end

  test "parses full names" do
    assert_equal ["Andrew Hsiao"], WikiPersonParser.parse("[[Andrew Hsiao]]")
  end

  test "dedupes repeated names preserving first occurrence" do
    assert_equal ["Andrew"], WikiPersonParser.parse("[[Andrew]] then [[Andrew]]")
  end
end
