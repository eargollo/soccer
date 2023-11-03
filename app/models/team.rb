# frozen_string_literal: true

class Team < ApplicationRecord
  has_many :home_matches, class_name: 'Match', foreign_key: 'team_home_id', dependent: :restrict_with_exception,
                          inverse_of: :team_home
  has_many :away_matches, class_name: 'Match', foreign_key: 'team_away_id', dependent: :restrict_with_exception,
                          inverse_of: :team_away

  def wins
    home_matches.won_home.count + away_matches.won_away.count
  end

  def losses
    home_matches.won_away.count + away_matches.won_home.count
  end

  def draws
    home_matches.draw.count + away_matches.draw.count
  end

  def goals_pro
    home_matches.finished.sum(:home_goals) + away_matches.finished.sum(:away_goals)
  end

  def goals_against
    home_matches.where(status: 'finished').sum(:away_goals) + away_matches.where(status: 'finished').sum(:home_goals)
  end
end
