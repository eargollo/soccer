# frozen_string_literal: true

class Standing < ApplicationRecord
  belongs_to :team
  belongs_to :season

  def rate
    100 * ((wins * 3) + draws) / (matches * 3.00)
  end

  def goals_difference
    goals_pro - goals_against
  end

  def last_simulation
    season.simulations.where.not(finish: nil)&.last&.simulation_standings&.find_by(team:) # rubocop:disable Style/SafeNavigationChainLength
  end

  def compute # rubocop:disable Metrics/AbcSize
    season = self

    find_or_initialize_by(team:).update(
      wins: team.wins(season:),
      draws: team.draws(season:),
      losses: team.losses(season:),
      goals_pro: team.goals_pro(season:),
      goals_against: team.goals_against(season:),
      points: (team.wins(season:) * 3) + team.draws(season:),
      matches: team.wins(season:) + team.draws(season:) + team.losses(season:)
    )
  end

  def self.compute(season:, team:)
    Standing.find_or_initialize_by(team:, season:).update(
      wins: team.wins(season:),
      draws: team.draws(season:),
      losses: team.losses(season:),
      goals_pro: team.goals_pro(season:),
      goals_against: team.goals_against(season:),
      points: (team.wins(season:) * 3) + team.draws(season:),
      matches: team.wins(season:) + team.draws(season:) + team.losses(season:)
    )
  end
end
