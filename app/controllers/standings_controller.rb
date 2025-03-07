# frozen_string_literal: true

class StandingsController < ApplicationController
  def index # rubocop:disable Metrics/AbcSize
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
    @show_simulation = @standings.last_simulation.present?
  end

  def show
    @season = Season.find(params[:id])

    if @season.nil?
      flash[:error] = "No season found" # rubocop:disable Rails/I18nLocaleTexts
      @standings = []
      return
    end

    @standings = @season.standings.order(points: :desc, wins: :desc)
    Rails.logger.info("Found #{@standings.count} standings for #{@season.league.name} #{@season.year}")
    return unless @standings.empty?

    @season.compute_standings
    @standings = @season.standings.order(points: :desc, wins: :desc)
    @show_simulation = @standings.last_simulation.present?
  end

  def list # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    season = Season.target_season
    direction = params[:direction] || "desc"

    @standings = season.standings
    @show_simulation = @standings.last_simulation.present?

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
    render(partial: "standings", locals: { standings: @standings })
  end
end
