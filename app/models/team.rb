class Team < ApplicationRecord
  has_many :home_matches, class_name: "Match", foreign_key: "team_home_id"
  has_many :away_matches, class_name: "Match", foreign_key: "team_away_id"

  def wins
    self.home_matches.where(status: "finished", result: "home").count + self.away_matches.where(status: "finished", result: "away").count
  end

  def losses
    self.home_matches.where(status: "finished", result: "away").count + self.away_matches.where(status: "finished", result: "home").count
  end

  def draws
    self.home_matches.where(status: "finished", result: "draw").count + self.away_matches.where(status: "finished", result: "draw").count
  end

  def goals_pro
    self.home_matches.where(status: "finished").sum(:home_goals) + self.away_matches.where(status: "finished").sum(:away_goals)
  end

  def goals_against
    self.home_matches.where(status: "finished").sum(:away_goals) + self.away_matches.where(status: "finished").sum(:home_goals)
  end
end
