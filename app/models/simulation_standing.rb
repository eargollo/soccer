# frozen_string_literal: true

class SimulationStanding < ApplicationRecord
  belongs_to :simulation
  belongs_to :team
end
