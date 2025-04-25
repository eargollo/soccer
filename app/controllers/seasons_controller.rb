# frozen_string_literal: true

class SeasonsController < ApplicationController
  def index
    season = Season.target_season

    if season == nil
      redirect_to(leagues_path)
      return
    end

    redirect_to(season_path(season))
  end

  def show
    @season = Season.find(params[:id])

    if @season.nil?
      flash[:error] = "No season found" # rubocop:disable Rails/I18nLocaleTexts
      @standings = []
      return
    end

    @standings = @season.standings.order(points: :desc, wins: :desc)
    @show_simulation = @season.last_simulation.present?
  end

  def list # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    season = params[:id].nil? ? Season.target_season : Season.find(params[:id])
    @season = season
    direction = params[:direction] || "desc"

    @standings = season.standings
    @show_simulation = season.last_simulation.present?

    @standings = @standings.sort_by { |standing| standing.team.name }
    @standings = case params[:column]
                 when "name"
                   @standings.sort_by { |standing| standing.team.name }
                 when "champion"
                   @standings.sort_by do |standing|
                     [standing.last_simulation&.champion || 0, -standing.last_simulation&.relegation || 0]
                   end
                 when "relegation"
                   @standings.sort_by do |standing|
                     [standing.last_simulation&.relegation || 0, -standing.last_simulation&.champion || 0]
                   end
                 else
                   @standings.sort_by do |standing|
                     [standing.send(params[:column]), standing.points, standing.wins, standing.goals_difference]
                   end
                 end

    @standings.reverse! if direction == "desc"
    render(partial: "season", locals: { standings: @standings })
  end
end
