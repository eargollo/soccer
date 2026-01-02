# frozen_string_literal: true

module Leagues
  class MatchesController < ApplicationController
    def index
      @league = League.find(params[:league_id])
      # Get matches from all seasons of this league, or from the most recent active season
      target_season = @league.seasons.where(active: true).order(year: :desc).first ||
                      @league.seasons.order(year: :desc).first

      if target_season.nil?
        flash[:error] = 'No seasons found for this league' # rubocop:disable Rails/I18nLocaleTexts
        @matches = []
        return
      end

      @matches = target_season.matches.order(:date, :round)
    end
  end
end
