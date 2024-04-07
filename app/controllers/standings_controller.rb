# frozen_string_literal: true

class StandingsController < ApplicationController
  def index
    season = Season.target_season

    @standings = season.standings.order(points: :desc, wins: :desc)
    Rails.logger.info("Found #{@standings.count} standings for #{season.league.name} #{season.year}")
    return unless @standings.empty?

    season.compute_standings
    @standings = season.standings.order(points: :desc, wins: :desc)
  end
end
