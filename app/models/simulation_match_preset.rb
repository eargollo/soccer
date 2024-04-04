# frozen_string_literal: true

class SimulationMatchPreset < ApplicationRecord
  belongs_to :match
  belongs_to :simulation
end
