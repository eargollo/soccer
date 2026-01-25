# frozen_string_literal: true

class CreateLeagueTeamProbabilities < ActiveRecord::Migration[7.1]
  def change
    create_table :league_teams do |t|
      t.references :league, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true

      # Home probabilities (from team's perspective when playing at home)
      t.decimal :home_prob_win, precision: 5, scale: 4, default: 0.0
      t.decimal :home_prob_draw, precision: 5, scale: 4, default: 0.0
      t.decimal :home_prob_loss, precision: 5, scale: 4, default: 0.0

      # Away probabilities (from team's perspective when playing away)
      t.decimal :away_prob_win, precision: 5, scale: 4, default: 0.0
      t.decimal :away_prob_draw, precision: 5, scale: 4, default: 0.0
      t.decimal :away_prob_loss, precision: 5, scale: 4, default: 0.0

      t.timestamps

      t.index %i[league_id team_id], unique: true
    end
  end
end
