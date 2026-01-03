# frozen_string_literal: true

module Leagues
  class MatchesController < ApplicationController
    def index
      @league = League.find(params[:league_id])
      season = @league.target_season

      if season.nil?
        flash[:error] = 'No seasons found for this league' # rubocop:disable Rails/I18nLocaleTexts
        @matches = []
        return
      end

      @matches = season.matches.order(:date, :round)
    end
  end
end
