class CreateEntryPeople < ActiveRecord::Migration[7.2]
  def change
    create_table :entry_people do |t|
      t.references :entry, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :entry_people, [:entry_id, :person_id], unique: true
  end
end
