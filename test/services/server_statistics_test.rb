require "test_helper"
require "minitest/mock"

class ServerStatisticsTest < ActiveSupport::TestCase
  setup do
    @person = Person.create!(name: "Andrew", slug: "andrew")
  end

  test "total entries counts all records" do
    create_entry!(title: "One", occurred_on: Date.current, primary: @person)
    create_entry!(title: "Two", occurred_on: Date.current, primary: @person)

    assert_equal 2, ServerStatistics.new.total_entries
  end

  test "entries created last 30 days uses created_at not occurred_on" do
    travel_to Time.zone.local(2026, 8, 15, 12, 0, 0) do
      recent = create_entry!(title: "Recent create", occurred_on: Date.new(2025, 1, 1), primary: @person)

      old_create = create_entry!(title: "Old create", occurred_on: Date.current, primary: @person)
      old_create.update_column(:created_at, 31.days.ago)

      just_inside = create_entry!(title: "Just inside", occurred_on: Date.new(2020, 1, 1), primary: @person)
      just_inside.update_column(:created_at, 30.days.ago + 1.hour)

      stats = ServerStatistics.new
      assert_equal 3, stats.total_entries
      assert_equal 2, stats.entries_created_last_30_days
      assert_equal [ recent.id, just_inside.id ].sort, Entry.where(created_at: 30.days.ago..Time.current).order(:id).pluck(:id)
      assert_not_includes Entry.where(created_at: 30.days.ago..Time.current).pluck(:id), old_create.id
    end
  end

  test "formatted database size is presented in MB with two decimals" do
    file = Tempfile.new([ "prm", ".sqlite3" ])
    file.write("x" * (1.10 * ServerStatistics::BYTES_PER_MB).round)
    file.flush

    label = ServerStatistics.new(database_path: file.path).formatted_database_size

    assert_match(/\A\d+\.\d{2} MB\z/, label)
    assert_equal "1.10 MB", label
  ensure
    file.close!
  end

  test "missing database file does not raise" do
    stats = ServerStatistics.new(database_path: "/tmp/missing-prm-db-#{SecureRandom.hex}.sqlite3")

    assert_equal "Unavailable", stats.formatted_database_size
  end

  test "filesystem errors do not raise" do
    file = Tempfile.new([ "prm", ".sqlite3" ])
    file.write("data")
    file.flush

    File.stub(:size, ->(*) { raise Errno::EACCES, "denied" }) do
      assert_equal "Unavailable", ServerStatistics.new(database_path: file.path).formatted_database_size
    end
  ensure
    file.close!
  end
end
