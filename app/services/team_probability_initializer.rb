# frozen_string_literal: true

class TeamProbabilityInitializer
  def self.call(league:, team:)
    new(league: league, team: team).call
  end

  def initialize(league:, team:)
    @league = league
    @team = team
  end

  def call
    league_team = @league.league_teams.find_or_initialize_by(team: @team)
    return league_team unless league_team.new_record?

    baseline = @league.baseline # [home_win, draw, home_loss]

    league_team.assign_attributes(
      home_prob_win: baseline[0],
      home_prob_draw: baseline[1],
      home_prob_loss: baseline[2],
      away_prob_win: baseline[2],   # flipped: home_loss → away_win
      away_prob_draw: baseline[1],
      away_prob_loss: baseline[0]   # flipped: home_win → away_loss
    )

    league_team.save!
    league_team
  end
end
