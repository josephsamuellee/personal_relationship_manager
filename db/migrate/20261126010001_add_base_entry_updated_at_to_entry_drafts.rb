class AddBaseEntryUpdatedAtToEntryDrafts < ActiveRecord::Migration[7.2]
  def change
    add_column :entry_drafts, :base_entry_updated_at, :datetime
  end
end
