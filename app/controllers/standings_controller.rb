# frozen_string_literal: true

class StandingsController < ApplicationController
  def index
    season = Season.target_season

    if season.nil?
      flash[:error] = "No active season found" # rubocop:disable Rails/I18nLocaleTexts
      @standings = []
      return
    end

    @standings = season.standings.order(points: :desc, wins: :desc)
    Rails.logger.info("Found #{@standings.count} standings for #{season.league.name} #{season.year}")
    return unless @standings.empty?

    season.compute_standings
    @standings = season.standings.order(points: :desc, wins: :desc)
  end

  def list # rubocop:disable Metrics/AbcSize
    season = Season.target_season
    direction = params[:direction] || "desc"

    @standings = case params[:column]
                 when "name"
                   season.standings.joins(:team).order(name: direction)
                 when "goals_difference"
                   season.standings.select("standings.*, goals_pro - goals_against AS goals_difference")
                         .order("goals_difference #{direction}")
                 when "rate"
                   season.standings.select("standings.*, ((wins*30000+draws*10000))/(3*matches) AS rate")
                         .order(rate: direction)
                 else
                   season.standings.order(params[:column] => direction)
                 end

    render(partial: "standings", locals: { standings: @standings })
  end
end
