# frozen_string_literal: true

class MatchProbabilityCalculator
  def self.call(match:, home_weight: Rails.application.config.probability.combiner_home_weight)
    new(match: match, home_weight: home_weight).call
  end

  def initialize(match:, home_weight:)
    @match = match
    @home_weight = home_weight
    @league = @match.league
  end

  def call
    ProbabilityCombiner.call(
      home_probabilities: home_team_probabilities,
      away_probabilities: away_team_probabilities,
      home_weight: @home_weight
    )
  end

  private

  def home_team_probabilities
    league_team = @league.league_teams.find_by(team: @match.team_home)
    return league_team.home_probabilities if league_team

    # Fall back to league baseline (already in home team format: [home_win, draw, home_loss])
    @league.baseline
  end

  def away_team_probabilities
    league_team = @league.league_teams.find_by(team: @match.team_away)
    return league_team.away_probabilities if league_team

    # Fall back to league baseline, flipped for away perspective
    @league.baseline.reverse
  end
end
