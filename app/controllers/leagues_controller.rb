# frozen_string_literal: true

class LeaguesController < ApplicationController
  before_action :authenticate_user!

  def show # rubocop:disable Metrics/AbcSize
    results = nil
    if params[:id] == "seed"
      if params[:league].present? && params[:season].present?
        Season.apifootball_seed(league_id: params[:league], season_id: params[:season])
      else
        Season.target_season&.seed
      end
    end

    render json: { param: params[:id], results: }
  end
end
