# frozen_string_literal: true

class LeagueStanding < ApplicationRecord
  self.table_name = "league_standings_matview"

  belongs_to :league
  belongs_to :team

  def rate
    100 * ((wins * 3) + draws) / (matches * 3.00)
  end

  def goals_difference
    goals_pro - goals_against
  end
end
