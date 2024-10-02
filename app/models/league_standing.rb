# frozen_string_literal: true

class LeagueStanding < ApplicationRecord
  self.table_name = "league_standings_matview"

  belongs_to :league
  belongs_to :team
end
