# frozen_string_literal: true

# == Schema Information
#
# Table name: simulation_match_presets
#
#  id            :bigint           not null, primary key
#  result        :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  match_id      :bigint           not null
#  simulation_id :bigint           not null
#
# Indexes
#
#  index_simulation_match_presets_on_match_id       (match_id)
#  index_simulation_match_presets_on_simulation_id  (simulation_id)
#
# Foreign Keys
#
#  fk_rails_...  (match_id => matches.id)
#  fk_rails_...  (simulation_id => simulations.id)
#
class SimulationMatchPreset < ApplicationRecord
  belongs_to :match
  belongs_to :simulation
end
