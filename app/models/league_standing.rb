# frozen_string_literal: true

class LeagueStanding < ApplicationRecord
  self.table_name = "league_standings_matview"

  belongs_to :league
  belongs_to :team

  def rate
    return 0 if matches.zero?

    100 * ((wins * 3) + draws) / (matches * 3.00)
  end

  def wins_rate
    return 0 if matches.zero?

    (100.0 * wins) / matches
  end

  def draws_rate
    return 0 if matches.zero?

    (100.0 * draws) / matches
  end

  def losses_rate
    return 0 if matches.zero?

    (100.0 * losses) / matches
  end

  def goals_difference
    goals_pro - goals_against
  end

  def self.refresh
    ActiveRecord::Base.connection.execute("REFRESH MATERIALIZED VIEW league_standings_matview;")
  end
end
