# frozen_string_literal: true

class Simulation < ApplicationRecord
  has_many :standings, class_name: "SimulationStanding", dependent: :destroy
  has_many :standing_positions, class_name: "SimulationStandingPosition", dependent: :destroy

  after_commit :simulate_job, on: :create

  private

  def simulate_job
    SimulateJob.perform_later(id)
  end
end
