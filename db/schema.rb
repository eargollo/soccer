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

ActiveRecord::Schema[7.2].define(version: 2024_04_06_212947) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "leagues", force: :cascade do |t|
    t.string "name", null: false
    t.integer "reference", null: false
    t.string "country"
    t.string "logo"
    t.string "flag"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "matches", force: :cascade do |t|
    t.datetime "date"
    t.bigint "team_home_id", null: false
    t.bigint "team_away_id", null: false
    t.string "status"
    t.integer "home_goals"
    t.integer "away_goals"
    t.string "result"
    t.integer "reference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "round"
    t.string "round_name"
    t.bigint "season_id", default: 1, null: false
    t.index ["season_id"], name: "index_matches_on_season_id"
    t.index ["team_away_id"], name: "index_matches_on_team_away_id"
    t.index ["team_home_id"], name: "index_matches_on_team_home_id"
  end

  create_table "seasons", force: :cascade do |t|
    t.integer "year", null: false
    t.bigint "league_id", null: false
    t.boolean "active", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["league_id"], name: "index_seasons_on_league_id"
  end

  create_table "simulation_match_presets", force: :cascade do |t|
    t.bigint "match_id", null: false
    t.bigint "simulation_id", null: false
    t.string "result"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["match_id"], name: "index_simulation_match_presets_on_match_id"
    t.index ["simulation_id"], name: "index_simulation_match_presets_on_simulation_id"
  end

  create_table "simulation_standing_positions", force: :cascade do |t|
    t.bigint "simulation_id", null: false
    t.bigint "team_id", null: false
    t.integer "position"
    t.integer "count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["simulation_id"], name: "index_simulation_standing_positions_on_simulation_id"
    t.index ["team_id"], name: "index_simulation_standing_positions_on_team_id"
  end

  create_table "simulation_standings", force: :cascade do |t|
    t.bigint "simulation_id", null: false
    t.bigint "team_id", null: false
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
    t.bigint "season_id", default: 1, null: false
    t.index ["season_id"], name: "index_simulations_on_season_id"
  end

  create_table "standings", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.integer "points"
    t.integer "matches"
    t.integer "wins"
    t.integer "draws"
    t.integer "losses"
    t.integer "goals_pro"
    t.integer "goals_against"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "season_id", default: 1, null: false
    t.index ["season_id"], name: "index_standings_on_season_id"
    t.index ["team_id"], name: "index_standings_on_team_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name"
    t.integer "reference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "logo"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "matches", "seasons"
  add_foreign_key "matches", "teams", column: "team_away_id"
  add_foreign_key "matches", "teams", column: "team_home_id"
  add_foreign_key "seasons", "leagues"
  add_foreign_key "simulation_match_presets", "matches"
  add_foreign_key "simulation_match_presets", "simulations"
  add_foreign_key "simulation_standing_positions", "simulations"
  add_foreign_key "simulation_standing_positions", "teams"
  add_foreign_key "simulation_standings", "simulations"
  add_foreign_key "simulation_standings", "teams"
  add_foreign_key "simulations", "seasons"
  add_foreign_key "standings", "seasons"
  add_foreign_key "standings", "teams"
end
