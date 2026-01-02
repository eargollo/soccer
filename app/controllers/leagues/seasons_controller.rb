# frozen_string_literal: true

module Leagues
  class SeasonsController < ApplicationController
    def index
      @league = League.find(params[:league_id])
      @seasons = @league.seasons.order(year: :desc)
    end

    def show
      @league = League.find(params[:league_id])
      @season = @league.seasons.find_by(id: params[:id])

      if @season.nil?
        flash[:alert] = "No season found" # rubocop:disable Rails/I18nLocaleTexts
        redirect_to(league_seasons_path(@league))
        return
      end

      @standings = @season.standings.order(points: :desc, wins: :desc)
      @show_simulation = @season.last_simulation.present?
    end

    def list # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
      @league = League.find(params[:league_id])
      season = params[:id].nil? ? @league.seasons.order(year: :desc).first : @league.seasons.find_by(id: params[:id])
      @season = season || @league.seasons.order(year: :desc).first

      if @season.nil?
        @standings = []
        render(partial: "season", locals: { standings: @standings })
        return
      end

      direction = params[:direction] || "desc"

      @standings = @season.standings
      @show_simulation = @season.last_simulation.present?

      @standings = @standings.sort_by { |standing| standing.team.name }
      @standings = case params[:column]
                   when "name"
                     @standings.sort_by { |standing| standing.team.name }
                   when "champion"
                     @standings.sort_by do |standing|
                       [standing.last_simulation&.champion || 0, -(standing.last_simulation&.relegation || 0)]
                     end
                   when "relegation"
                     @standings.sort_by do |standing|
                       [standing.last_simulation&.relegation || 0, -(standing.last_simulation&.champion || 0)]
                     end
                   when nil
                     @standings.sort_by do |standing|
                       [standing.points, standing.wins, standing.goals_difference, standing.goals_pro]
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
end
