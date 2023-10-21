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

ActiveRecord::Schema[7.1].define(version: 2023_10_20_234705) do
  create_table "matches", force: :cascade do |t|
    t.datetime "date"
    t.integer "team_home_id", null: false
    t.integer "teams_id", null: false
    t.integer "team_away_id", null: false
    t.integer "teans_id", null: false
    t.string "status"
    t.integer "home_goals"
    t.integer "away_goals"
    t.string "result"
    t.integer "reference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_away_id"], name: "index_matches_on_team_away_id"
    t.index ["team_home_id"], name: "index_matches_on_team_home_id"
    t.index ["teams_id"], name: "index_matches_on_teams_id"
    t.index ["teans_id"], name: "index_matches_on_teans_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name"
    t.integer "reference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "matches", "team_aways"
  add_foreign_key "matches", "team_homes"
  add_foreign_key "matches", "teams", column: "teams_id"
  add_foreign_key "matches", "teans", column: "teans_id"
end
