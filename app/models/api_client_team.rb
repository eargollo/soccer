# frozen_string_literal: true

# == Schema Information
#
# Table name: api_client_teams
#
#  id         :bigint           not null, primary key
#  client_key :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  client_id  :integer
#  team_id    :bigint           not null
#
# Indexes
#
#  index_api_client_teams_on_team_id  (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
class ApiClientTeam < ApplicationRecord
  belongs_to :team
end
