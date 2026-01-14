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

  def show # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    @team = Team.find(params[:id])

    # Get all leagues where this team has played from the materialized league_standings view
    league_ids = @team.league_standings.pluck(:league_id).uniq
    @leagues = League.where(id: league_ids).order(:name)

    # Redirect to first league if no league_id is provided
    redirect_to team_path(@team, league_id: @leagues.first.id) and return if params[:league_id].blank? && @leagues.any?

    # Get the selected league from params
    selected_league_id = params[:league_id]&.to_i
    @selected_league = if selected_league_id && @leagues.map(&:id).include?(selected_league_id)
                         @leagues.find { |l| l.id == selected_league_id }
                       elsif @leagues.any?
                         @leagues.first
                       end

    # Build summary only for the selected league
    @current_league_summary = @selected_league ? build_league_summary(@selected_league) : nil
  end

  private

  def build_league_summary(league) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    # Get all matches for this team in this league
    league_matches = Match.joins(:season)
                          .where(seasons: { league_id: league.id })
                          .where('team_home_id = ? OR team_away_id = ?', @team.id, @team.id)
                          .includes(:team_home, :team_away, :season)

    # Get all unique opponents
    opponent_ids = league_matches.map do |match|
      match.team_home_id == @team.id ? match.team_away_id : match.team_home_id
    end.uniq

    opponents = Team.where(id: opponent_ids).order(:name)

    # Build opponent statistics
    opponent_stats = opponents.map do |opponent| # rubocop:disable Metrics/BlockLength, Metrics/BlockLength
      home_matches = league_matches.select { |m| m.team_home_id == @team.id && m.team_away_id == opponent.id }
      away_matches = league_matches.select { |m| m.team_away_id == @team.id && m.team_home_id == opponent.id }
      all_matches = home_matches + away_matches

      {
        opponent: opponent,
        home: {
          played: home_matches.count(&:finished?),
          wins: home_matches.count { |m| m.finished? && m.result == 'home' },
          draws: home_matches.count { |m| m.finished? && m.result == 'draw' },
          losses: home_matches.count { |m| m.finished? && m.result == 'away' }
        },
        away: {
          played: away_matches.count(&:finished?),
          wins: away_matches.count { |m| m.finished? && m.result == 'away' },
          draws: away_matches.count { |m| m.finished? && m.result == 'draw' },
          losses: away_matches.count { |m| m.finished? && m.result == 'home' }
        },
        total: {
          played: all_matches.count(&:finished?),
          wins: all_matches.count do |m|
            m.finished? && (m.result == (m.team_home_id == @team.id ? 'home' : 'away'))
          end,
          draws: all_matches.count { |m| m.finished? && m.result == 'draw' },
          losses: all_matches.count do |m|
            m.finished? && (m.result == (m.team_home_id == @team.id ? 'away' : 'home'))
          end
        }
      }
    end

    {
      league: league,
      opponents: opponent_stats
    }
  end
end
