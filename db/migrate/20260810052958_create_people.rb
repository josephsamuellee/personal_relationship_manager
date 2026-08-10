class CreatePeople < ActiveRecord::Migration[7.2]
  def change
    create_table :people do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :about_markdown, null: false, default: ""

      t.timestamps
    end
    add_index :people, :slug, unique: true
    add_index :people, :name
  end
end
