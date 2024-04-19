# frozen_string_literal: true

class MatchesController < ApplicationController
  def index
    season = Season.target_season
    if season.nil?
      flash[:error] = 'No active season found' # rubocop:disable Rails/I18nLocaleTexts
      @matches = []
      return
    end

    @matches = Season.target_season.matches
  end
end
