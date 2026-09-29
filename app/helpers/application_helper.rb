module ApplicationHelper
  def new_entry_path_for_date(date)
    new_entry_path(occurred_on: date.iso8601)
  end
end
