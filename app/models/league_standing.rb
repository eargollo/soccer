# frozen_string_literal: true

# == Schema Information
#
# Table name: league_standings_matview
#
#  draws         :bigint
#  goals_against :bigint
#  goals_pro     :bigint
#  last_season   :integer
#  losses        :bigint
#  matches       :bigint
#  points        :bigint
#  seasons       :bigint
#  wins          :bigint
#  league_id     :bigint
#  team_id       :bigint
#
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
    # TODO: Change to
    # Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: false)
  end
end
