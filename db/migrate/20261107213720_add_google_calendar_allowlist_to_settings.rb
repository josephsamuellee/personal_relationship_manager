class AddGoogleCalendarAllowlistToSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :settings, :google_calendar_allowlist, :text
  end
end
