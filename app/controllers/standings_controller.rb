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

  def list # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    season = Season.target_season
    direction = params[:direction] || "desc"

    @standings = season.standings

    @standings = @standings.sort_by { |standing| standing.team.name }
    @standings = case params[:column]
                 when "name"
                   @standings.sort_by { |standing| standing.team.name }
                 when "champion"
                   @standings.sort_by { |standing| standing.last_simulation&.champion || 0 }
                 when "relegation"
                   @standings.sort_by { |standing| standing.last_simulation&.relegation || 0 }
                 else
                   @standings.sort_by { |standing| standing.send(params[:column]) }
                 end

    @standings.reverse! if direction == "desc"
    render(partial: "standings", locals: { standings: @standings })
  end
end
