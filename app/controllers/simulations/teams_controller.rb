# frozen_string_literal: true

module Simulations
  class TeamsController < ApplicationController
    def show
      @team = Team.find(params[:id])
      @simulation = Simulation.find(params[:simulation_id])
      @positions = SimulationStandingPosition.where(simulation_id: params[:simulation_id],
                                                    team_id: params[:id]).order(:position)
    end
  end
end
