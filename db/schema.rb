# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_08_10_053001) do
  create_table "entries", force: :cascade do |t|
    t.string "title", null: false
    t.date "occurred_on", null: false
    t.text "body_markdown", null: false
    t.integer "primary_person_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["occurred_on"], name: "index_entries_on_occurred_on"
    t.index ["primary_person_id"], name: "index_entries_on_primary_person_id"
  end

  create_table "entry_people", force: :cascade do |t|
    t.integer "entry_id", null: false
    t.integer "person_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entry_id", "person_id"], name: "index_entry_people_on_entry_id_and_person_id", unique: true
    t.index ["entry_id"], name: "index_entry_people_on_entry_id"
    t.index ["person_id"], name: "index_entry_people_on_person_id"
  end

  create_table "entry_tags", force: :cascade do |t|
    t.integer "entry_id", null: false
    t.integer "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entry_id"], name: "index_entry_tags_on_entry_id"
    t.index ["tag_id"], name: "index_entry_tags_on_tag_id"
  end

  create_table "people", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "about_markdown", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_people_on_name"
    t.index ["slug"], name: "index_people_on_slug", unique: true
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  add_foreign_key "entries", "people", column: "primary_person_id"
  add_foreign_key "entry_people", "entries"
  add_foreign_key "entry_people", "people"
  add_foreign_key "entry_tags", "entries"
  add_foreign_key "entry_tags", "tags"
end
