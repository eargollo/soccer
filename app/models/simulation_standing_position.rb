class SimulationStandingPosition < ApplicationRecord
  belongs_to :simulation
  belongs_to :team
end
