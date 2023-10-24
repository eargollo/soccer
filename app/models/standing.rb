# frozen_string_literal: true

class Standing < ApplicationRecord
  belongs_to :team

  def self.compute(team)
    standing = Standing.find_by(team: team)
    if standing.nil?
      standing = Standing.new(team: team)
    end
    standing.wins = 0
    standing.draws = 0
    standing.losses = 0
    standing.points = 0
    standing.matches = 0
    standing.goals_pro = 0
    standing.goals_against = 0

    Match.where(team_home: team, status: "finished").group(:result).count(:result).each do |k,v|
      if k == "home"
        standing.wins += v
      end

      if k == "draw"
        standing.draws += v
      end

      if k == "away"
        standing.losses += v
      end
    end
    Match.where(team_away: team, status: "finished").group(:result).count(:result).each do |k, v|
      if k == "home"
        standing.losses += v
      end

      if k == "draw"
        standing.draws += v
      end

      if k == "away"
        standing.wins += v
      end
    end
    # calculate points
    standing.points = standing.wins * 3 + standing.draws
    standing.matches = standing.wins + standing.draws + standing.losses

    # Calculate goals
    goals = Match.where(team_home: team, status: "finished").pluck('SUM(home_goals)','SUM(away_goals)')
    standing.goals_pro = goals[0][0] || 0
    standing.goals_against = goals[0][1] || 0

    goals = Match.where(team_away: team, status: "finished").pluck('SUM(home_goals)','SUM(away_goals)')
    standing.goals_pro += goals[0][1] || 0
    standing.goals_against += goals[0][0] || 0

    standing.save
  end
end
