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

ActiveRecord::Schema[7.1].define(version: 2023_10_26_051343) do
  create_table "matches", force: :cascade do |t|
    t.datetime "date"
    t.integer "team_home_id", null: false
    t.integer "team_away_id", null: false
    t.string "status"
    t.integer "home_goals"
    t.integer "away_goals"
    t.string "result"
    t.integer "reference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_away_id"], name: "index_matches_on_team_away_id"
    t.index ["team_home_id"], name: "index_matches_on_team_home_id"
  end

  create_table "simulation_standing_positions", force: :cascade do |t|
    t.integer "simulation_id", null: false
    t.integer "team_id", null: false
    t.integer "position"
    t.integer "count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["simulation_id"], name: "index_simulation_standing_positions_on_simulation_id"
    t.index ["team_id"], name: "index_simulation_standing_positions_on_team_id"
  end

  create_table "simulation_standings", force: :cascade do |t|
    t.integer "simulation_id", null: false
    t.integer "team_id", null: false
    t.float "champion"
    t.float "promotion"
    t.float "relegation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["simulation_id"], name: "index_simulation_standings_on_simulation_id"
    t.index ["team_id"], name: "index_simulation_standings_on_team_id"
  end

  create_table "simulations", force: :cascade do |t|
    t.string "name"
    t.integer "runs"
    t.datetime "start"
    t.datetime "finish"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "standings", force: :cascade do |t|
    t.integer "team_id", null: false
    t.integer "points"
    t.integer "matches"
    t.integer "wins"
    t.integer "draws"
    t.integer "losses"
    t.integer "goals_pro"
    t.integer "goals_against"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_standings_on_team_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name"
    t.integer "reference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "matches", "teams", column: "team_away_id"
  add_foreign_key "matches", "teams", column: "team_home_id"
  add_foreign_key "simulation_standing_positions", "simulations"
  add_foreign_key "simulation_standing_positions", "teams"
  add_foreign_key "simulation_standings", "simulations"
  add_foreign_key "simulation_standings", "teams"
  add_foreign_key "standings", "teams"
end
