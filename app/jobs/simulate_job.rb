# frozen_string_literal: true

class SimulateJob < ApplicationJob
  queue_as :default

  def perform(id)
    Simulation.find_by(id:)&.run
  end
end
