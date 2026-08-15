ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)

  def create_entry!(title:, occurred_on:, primary:, people: nil, body: nil, tags: [])
    associated = people || [primary]
    entry = Entry.create!(
      title: title,
      occurred_on: occurred_on,
      body_markdown: body || title,
      primary_person: primary
    )
    associated.each_with_index do |person, index|
      entry.entry_people.create!(person: person, position: index)
    end
    tags.each do |name|
      entry.entry_tags.create!(tag: Tag.find_or_create_by_normalized!(name))
    end
    entry
  end
end
