# frozen_string_literal: true

class LeaguesController < ApplicationController
  before_action :authenticate_user!

  def show # rubocop:disable Metrics/AbcSize
    results = "missing ID parameter"
    if params[:id] == "seed"
      if params[:league].present? && params[:season].present?
        imported = Season.apifootball_seed(league_id: params[:league], season_id: params[:season])
        results = "imported league #{imported.league.name} season #{imported.year}"
      elsif Season.target_season.nil?
        results = "Error: no target season. Try with league and season id ?league=71&&season=2024 for instance"
      else
        results = "seeded target season #{Season.target_season.league.name} #{Season.target_season&.year}"
        Season.target_season&.seed
      end
    end

    render json: { param: params[:id], results: }
  end
end
