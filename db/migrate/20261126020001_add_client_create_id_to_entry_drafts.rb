class AddClientCreateIdToEntryDrafts < ActiveRecord::Migration[7.2]
  def change
    add_column :entry_drafts, :client_create_id, :string
    add_index :entry_drafts, :client_create_id, unique: true
  end
end
