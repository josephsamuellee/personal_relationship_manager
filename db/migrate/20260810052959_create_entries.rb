class CreateEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :entries do |t|
      t.string :title, null: false
      t.date :occurred_on, null: false
      t.text :body_markdown, null: false
      t.references :primary_person, null: false, foreign_key: { to_table: :people }

      t.timestamps
    end
    add_index :entries, :occurred_on
  end
end
