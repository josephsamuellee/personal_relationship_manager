class AddFavoritePeopleToSettings < ActiveRecord::Migration[7.2]
  def change
    change_table :settings, bulk: true do |t|
      t.integer :favorite_person_1_id
      t.integer :favorite_person_2_id
      t.integer :favorite_person_3_id
    end

    add_index :settings, :favorite_person_1_id
    add_index :settings, :favorite_person_2_id
    add_index :settings, :favorite_person_3_id

    add_foreign_key :settings, :people, column: :favorite_person_1_id, on_delete: :nullify
    add_foreign_key :settings, :people, column: :favorite_person_2_id, on_delete: :nullify
    add_foreign_key :settings, :people, column: :favorite_person_3_id, on_delete: :nullify
  end
end
