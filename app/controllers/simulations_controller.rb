# frozen_string_literal: true

class SimulationsController < ApplicationController
  def index
    @simulations = Simulation.all
  end

  def show
    @simulation = Simulation.find(params[:id])
  end

  def new
    @simulation = Simulation.new
  end

  def create
    @simulation = Simulation.new(simulation_params)
    if @simulation.save
      redirect_to @simulation
    else
      render :new
    end
  end

  private

  def simulation_params
    params.require(:simulation).permit(:name, :runs)
  end
end
