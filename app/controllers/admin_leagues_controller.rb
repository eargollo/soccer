# frozen_string_literal: true

class AdminLeaguesController < ApplicationController
  before_action :authenticate_user!

  def index
    @leagues = League.all
  end

  def show
    @league = League.find(params[:id])
    @seasons = @league.seasons
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
