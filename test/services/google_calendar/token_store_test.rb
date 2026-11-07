require "test_helper"

class GoogleCalendar::TokenStoreTest < ActiveSupport::TestCase
  setup do
    @path = Rails.root.join("tmp", "test_google_tokens_#{SecureRandom.hex(4)}.json.enc")
    @store = GoogleCalendar::TokenStore.new(path: @path)
  end

  teardown do
    FileUtils.rm_f(@path)
  end

  test "stores and loads encrypted tokens" do
    @store.store("prm", '{"access_token":"secret-token"}')

    assert File.exist?(@path)
    refute_includes File.binread(@path), "secret-token"
    assert_equal '{"access_token":"secret-token"}', @store.load("prm")
  end

  test "delete and clear remove tokens" do
    @store.store("prm", '{"refresh_token":"r"}')
    @store.delete("prm")

    assert_nil @store.load("prm")

    @store.store("prm", '{"refresh_token":"r2"}')
    @store.clear!
    refute File.exist?(@path)
  end
end
