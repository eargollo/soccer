# frozen_string_literal: true

class SimulateJob < ApplicationJob
  queue_as :default

  def perform(id)
    simulation = Simulation.find_by(id:)
    raise "Simulation #{id} does not exist" if simulation.nil?

    unless simulation.start.nil?
      Rails.logger.warn("Simulation #{id} is already executing since #{simulation.start}. Skipping this job.") 
      return
    end
    simulation.run
  end
end
