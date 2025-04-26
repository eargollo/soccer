# frozen_string_literal: true

# == Schema Information
#
# Table name: simulation_standing_positions
#
#  id            :bigint           not null, primary key
#  count         :integer
#  position      :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  simulation_id :bigint           not null
#  team_id       :bigint           not null
#
# Indexes
#
#  index_simulation_standing_positions_on_simulation_id  (simulation_id)
#  index_simulation_standing_positions_on_team_id        (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (simulation_id => simulations.id)
#  fk_rails_...  (team_id => teams.id)
#
require "test_helper"

class SimulationStandingPositionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
