# frozen_string_literal: true

class SimulationsController < ApplicationController
  def index
    @simulations = Simulation.all
  end

  def show
    @simulation = Simulation.find(params[:id])
    @matches = @simulation.simulation_match_presets
  end

  def new
    @simulation = Simulation.new
    @matches = Match.pending.all
  end

  def create
    matches = params[:matches]
    @simulation = Simulation.new(simulation_params)
    if @simulation.save
      matches.each do |match_id, result|
        @simulation.simulation_match_presets.create(match_id: match_id, result: result)
      end
      redirect_to @simulation
    else
      render :new
    end
  end

  private

  def simulation_params
    params.require(:simulation).permit(:name, :runs, :matches)
  end
end
