# frozen_string_literal: true

class AdminLeaguesController < AdminController
  def index
    @leagues = League.all
    apply_sorting if params[:column].present?
  end

  private

  def apply_sorting
    column = params[:column]
    direction = params[:direction] || "asc"

    # Validate column to prevent SQL injection
    valid_columns = %w[id name country reference]
    return unless valid_columns.include?(column)

    @leagues = @leagues.order(column => direction.to_sym)
  end

  def show
    @league = League.find(params[:id])
    @seasons = @league.seasons.order(year: :desc)
  end

  def new
    @league = League.new
  end

  def create # rubocop:disable Metrics/AbcSize
    reference = params[:league][:reference]
    season = params[:season]
    if reference.blank? || season.blank?
      redirect_to new_admin_league_path
      return
    end

    imported = Season.apifootball_seed(league_id: reference, season_id: season)
    LeagueStanding.refresh

    flash[:notice] = "imported league #{imported.league.name} season #{imported.year}"
    redirect_to admin_leagues_path
  end
end
