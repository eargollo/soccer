# frozen_string_literal: true

class SimulationStandingsController < ApplicationController
  def show
    @sim_standing = SimulationStanding.find(params[:id])
    @positions = SimulationStandingPosition.where(team: @sim_standing.team,
                                                  simulation: @sim_standing.simulation).order(:position)
    @season = @sim_standing.simulation.season
  end
end
