# frozen_string_literal: true

class TeamsController < ApplicationController
  def index # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    # Get all teams sorted alphabetically
    @teams = Team.order(:name).includes(:league_standings)

    # Build team data with aggregated stats across all leagues
    @team_data = @teams.map do |team|
      league_standings = team.league_standings

      total_matches = league_standings.sum(&:matches)
      total_wins = league_standings.sum(&:wins)
      total_draws = league_standings.sum(&:draws)

      {
        team: team,
        seasons_played: league_standings.sum(&:seasons) || 0,
        last_season: league_standings.maximum(:last_season),
        points_rate: total_matches.zero? ? 0.0 : (100 * ((total_wins * 3) + total_draws) / (total_matches * 3.00))
      }
    end
  end
end
