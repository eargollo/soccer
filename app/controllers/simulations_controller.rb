# frozen_string_literal: true

class SimulationsController < ApplicationController
  before_action :authenticate_user!, only: %i[new create]

  def index
    @simulations = Simulation.all
  end

  def show
    @simulation = Simulation.find(params[:id])
    @matches = @simulation.simulation_match_presets
  end

  def new
    @simulation = Season.target_season.simulations.new
    @matches = Season.target_season.matches.pending.all
  end

  def create
    matches = params[:matches]
    @simulation = Simulation.new(simulation_params)
    if @simulation.save
      matches&.each do |match_id, result|
        @simulation.simulation_match_presets.create(match_id:, result:)
      end
      redirect_to @simulation
    else
      render :new
    end
  end

  private

  def simulation_params
    params.expect(simulation: %i[season_id name runs matches])
  end
end
