# frozen_string_literal: true

class Team < ApplicationRecord
  has_many :home_matches, class_name: 'Match', foreign_key: 'team_home_id', dependent: :restrict_with_exception,
                          inverse_of: :team_home
  has_many :away_matches, class_name: 'Match', foreign_key: 'team_away_id', dependent: :restrict_with_exception,
                          inverse_of: :team_away

  has_many :standings, dependent: :restrict_with_exception
  has_many :simulation_standings, dependent: :restrict_with_exception

  def wins(season: nil) # rubocop:disable Metrics/AbcSize
    return home_matches.won_home.count + away_matches.won_away.count if season.nil?

    home_matches.won_home.where(season:).count + away_matches.won_away.where(season:).count
  end

  def losses(season: nil) # rubocop:disable Metrics/AbcSize
    return home_matches.won_away.count + away_matches.won_home.count if season.nil?

    home_matches.won_away.where(season:).count + away_matches.won_home.where(season:).count unless season.nil?
  end

  def draws(season: nil) # rubocop:disable Metrics/AbcSize
    return home_matches.draw.count + away_matches.draw.count if season.nil?

    home_matches.draw.where(season:).count + away_matches.draw.where(season:).count unless season.nil?
  end

  def goals_pro(season: nil) # rubocop:disable Metrics/AbcSize
    return home_matches.finished.sum(:home_goals) + away_matches.finished.sum(:away_goals) if season.nil?

    home_matches.where(season:).finished.sum(:home_goals) + away_matches.where(season:).finished.sum(:away_goals)
  end

  def goals_against(season: nil) # rubocop:disable Metrics/AbcSize
    if season.nil?
      return home_matches.where(status: 'Match Finished').sum(:away_goals) +
             away_matches.where(status: 'Match Finished').sum(:home_goals)
    end

    home_matches.where(season:).finished.sum(:away_goals) + away_matches.where(season:).finished.sum(:home_goals)
  end
end
