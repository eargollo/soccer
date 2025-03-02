# frozen_string_literal: true

class LeagueStandingsController < ApplicationController
  # before_action :authenticate_user!

  def index
    @leagues = League.all
  end

  def show
    @league = League.find(params[:id])
    @standings = @league.league_standings.where(league_id: params[:id]).order(points: :desc, wins: :desc)
    @last_season = @standings.first.league.seasons.maximum(:year)
  end

  def list # rubocop:disable Metrics/AbcSize
    direction = params[:direction] || "desc"

    @league = League.find(params[:id])
    @standings = @league.league_standings.where(league_id: params[:id]).order(points: :desc, wins: :desc)
    @last_season = @standings.first.league.seasons.maximum(:year)

    @standings = @standings.sort_by { |standing| standing.team.name }
    @standings = case params[:column]
                 when "name"
                   @standings.sort_by { |standing| standing.team.name }
                 else
                   @standings.sort_by do |standing|
                     [standing.send(params[:column]), standing.points, standing.wins, standing.goals_difference]
                   end
                 end

    @standings.reverse! if direction == "desc"
    render(partial: "standings", locals: { standings: @standings })
  end
end
