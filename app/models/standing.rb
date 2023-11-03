# frozen_string_literal: true

class Standing < ApplicationRecord
  belongs_to :team

  def self.compute(team) # rubocop:disable Metrics/AbcSize
    Standing.find_or_initialize_by(team:).update(
      wins: team.wins,
      draws: team.draws,
      losses: team.losses,
      goals_pro: team.goals_pro,
      goals_against: team.goals_against,
      points: (standing.wins * 3) + standing.draws,
      matches: standing.wins + standing.draws + standing.losses
    )
  end
end
