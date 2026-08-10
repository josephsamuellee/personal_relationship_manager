def create_person!(name)
  Person.find_or_create_by!(slug: name.parameterize) { |p| p.name = name }
end

def create_entry!(title:, occurred_on:, body:, people:, tags: [])
  draft = EntryDraft.new(
    title: title,
    raw_date: occurred_on.strftime("%d %b %Y"),
    body_markdown: body
  )
  draft.occurred_on = occurred_on
  draft.parsed_people = WikiPersonParser.parse(body)
  draft.parsed_tags = TagParser.parse(body)
  draft.resolved_people_ids = people.map(&:id)
  draft.validation_errors = []
  EntrySaver.save!(draft)
end

andrew = create_person!("Andrew")
sarah = create_person!("Sarah")
andrew_hsiao = create_person!("Andrew Hsiao")
andrew_wang = create_person!("Andrew Wang")

today = Date.current

create_entry!(
  title: "Coffee catch-up",
  occurred_on: today - 2.years,
  body: "Met [[Andrew]] for coffee downtown.",
  people: [andrew],
  tags: ["coffee"]
)

create_entry!(
  title: "Dinner at Din Tai Fung",
  occurred_on: today - 1.year,
  body: "Dinner with [[Andrew Hsiao]] and [[Sarah]] at Din Tai Fung.\n\n#dinner",
  people: [andrew_hsiao, sarah],
  tags: ["dinner"]
)

create_entry!(
  title: "Church sermon",
  occurred_on: today.beginning_of_week,
  body: "Sunday service with [[Sarah]].\n\n#church",
  people: [sarah],
  tags: ["church"]
)

create_entry!(
  title: "Weekly review",
  occurred_on: today.beginning_of_week,
  body: "Personal weekly review.\n\n[[Andrew]]",
  people: [andrew],
  tags: ["review"]
)

create_entry!(
  title: "Andrew dinner",
  occurred_on: today.beginning_of_week + 1.day,
  body: "Dinner with [[Andrew Wang]].\n\n#dinner",
  people: [andrew_wang],
  tags: ["dinner"]
)

create_entry!(
  title: "Work journal",
  occurred_on: today.beginning_of_week + 1.day,
  body: "Busy day at work. Checked in with [[Sarah]].",
  people: [sarah]
)

anchor = today - 3.months
create_entry!(
  title: "Spring hike",
  occurred_on: anchor,
  body: "Hiked with [[Andrew Hsiao]].\n\n#vacation",
  people: [andrew_hsiao],
  tags: ["vacation"]
)

create_entry!(
  title: "Dinner with parents",
  occurred_on: today.beginning_of_week,
  body: "Family dinner with [[Andrew]].\n\n#dinner",
  people: [andrew],
  tags: ["dinner"]
)

andrew_hsiao.update!(about_markdown: "Works in accounting.\n\nLikes hiking and Taiwanese food.\n\nMet through [[Sarah]].")

puts "Seeded #{Person.count} people, #{Entry.count} entries, #{Tag.count} tags"
