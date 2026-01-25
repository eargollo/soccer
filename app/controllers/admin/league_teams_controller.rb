# frozen_string_literal: true

module Admin
  class LeagueTeamsController < AdminController
    before_action :set_league
    before_action :set_league_team, only: %i[show recalculate]

    def index
      @league_teams = @league.league_teams.includes(:team)
      if params[:column].present?
        apply_sorting
      else
        # Default sort by team name if no sort specified
        @league_teams = @league_teams.order('teams.name ASC')
      end
    end

    def show; end

    def recalculate # rubocop:disable Metrics/AbcSize
      if @league_team
        ProbabilityRecalculator.call(league: @league, team: @league_team.team)
        flash[:notice] = "Recalculated probabilities for #{@league_team.team.name}"
        redirect_to admin_league_league_team_path(admin_league_id: @league.id, id: @league_team.id)
      else
        ProbabilityRecalculator.call(league: @league)
        flash[:notice] = "Recalculated probabilities for all teams in #{@league.name}"
        redirect_to admin_league_league_teams_path(admin_league_id: @league.id)
      end
    end

    private

    def apply_sorting
      column = params[:column]
      direction = params[:direction] || "asc"

      # Validate column to prevent SQL injection
      valid_columns = %w[team_name home_prob_win home_prob_draw home_prob_loss away_prob_win away_prob_draw
                         away_prob_loss]
      return unless valid_columns.include?(column)

      @league_teams = case column
                      when "team_name"
                        @league_teams.order("teams.name #{direction.upcase}")
                      else
                        # Sort by probability columns directly
                        @league_teams.order("#{column} #{direction.upcase}")
                      end
    end

    def set_league
      @league = League.find(params[:admin_league_id])
    end

    def set_league_team
      @league_team = @league.league_teams.find_by(id: params[:id]) if params[:id]
    end
  end
end
