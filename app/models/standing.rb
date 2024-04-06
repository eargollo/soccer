# frozen_string_literal: true

class Standing < ApplicationRecord
  belongs_to :team
  belongs_to :season

  def self.compute(team)
    Standing.find_or_initialize_by(team:).update(
      wins: team.wins,
      draws: team.draws,
      losses: team.losses,
      goals_pro: team.goals_pro,
      goals_against: team.goals_against,
      points: (team.wins * 3) + team.draws,
      matches: team.wins + team.draws + team.losses
    )
  end
end
