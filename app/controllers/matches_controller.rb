# frozen_string_literal: true

class MatchesController < ApplicationController
  def index
    @matches = Season.target_season.matches
  end
end
