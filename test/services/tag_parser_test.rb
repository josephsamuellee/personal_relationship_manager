require "test_helper"

class TagParserTest < ActiveSupport::TestCase
  test "parses and normalizes tags" do
    assert_equal %w[church dinner], TagParser.parse("#church #Dinner")
  end

  test "normalize removes hash and lowercases" do
    assert_equal "church", TagParser.normalize("#Church")
  end
end
