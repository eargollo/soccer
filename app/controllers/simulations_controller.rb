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
end
