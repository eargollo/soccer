# frozen_string_literal: true

class Standing < ApplicationRecord
  belongs_to :team

  def self.compute(team) # rubocop:disable Metrics/AbcSize
    standing = Standing.find_or_initialize_by(
      team:
    )

    standing.wins = team.wins
    standing.draws = team.draws
    standing.losses = team.losses
    standing.goals_pro = team.goals_pro
    standing.goals_against = team.goals_against
    standing.points = (standing.wins * 3) + standing.draws
    standing.matches = standing.wins + standing.draws + standing.losses

    # puts "Standing to save is #{standing.inspect}"
    standing.save
  end
end
