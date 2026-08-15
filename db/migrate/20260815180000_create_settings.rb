class CreateSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :settings do |t|
      t.string :theme, null: false, default: "dark"

      t.timestamps
    end
  end
end
