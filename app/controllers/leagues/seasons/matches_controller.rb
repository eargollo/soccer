# frozen_string_literal: true

module Leagues
  module Seasons
    class MatchesController < ApplicationController
      def index
        @league = League.find(params[:league_id])
        @season = @league.seasons.find_by(id: params[:season_id])

        if @season.nil?
          flash[:error] = 'No season found' # rubocop:disable Rails/I18nLocaleTexts
          redirect_to(league_seasons_path(@league))
          return
        end

        @matches = @season.matches.order(:date, :round)
      end
    end
  end
end
