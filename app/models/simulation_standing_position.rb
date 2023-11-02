# frozen_string_literal: true

class SimulationStandingPosition < ApplicationRecord
  belongs_to :simulation
  belongs_to :team
end
