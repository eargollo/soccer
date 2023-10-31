# frozen_string_literal: true

class SimulateJob < ApplicationJob
  queue_as :default

  def perform(id)
    Simulation.find(id).run
  end
end
