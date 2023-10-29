# frozen_string_literal: true

class SimulateJob < ApplicationJob
  queue_as :default

  def perform(sim)
    sim.run
  end
end
