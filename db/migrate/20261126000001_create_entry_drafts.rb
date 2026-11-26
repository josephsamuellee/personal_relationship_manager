class CreateEntryDrafts < ActiveRecord::Migration[7.2]
  def change
    create_table :entry_drafts do |t|
      t.references :entry, null: true, foreign_key: { on_delete: :nullify }, index: { unique: true }
      t.string :title
      t.string :raw_date
      t.text :body_markdown, null: false, default: ""
      t.text :person_selections, null: false, default: "{}"
      t.integer :lock_version, null: false, default: 0
      t.datetime :content_updated_at, null: false
      t.timestamps
    end
  end
end
