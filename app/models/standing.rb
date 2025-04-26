# frozen_string_literal: true

# == Schema Information
#
# Table name: standings
#
#  id            :bigint           not null, primary key
#  draws         :integer
#  goals_against :integer
#  goals_pro     :integer
#  losses        :integer
#  matches       :integer
#  points        :integer
#  position      :integer
#  wins          :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  season_id     :bigint           default(1), not null
#  team_id       :bigint           not null
#
# Indexes
#
#  index_standings_on_season_id  (season_id)
#  index_standings_on_team_id    (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (season_id => seasons.id)
#  fk_rails_...  (team_id => teams.id)
#
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
