class Team < ApplicationRecord
  has_many :matches_as_home, class_name: "Match", foreign_key: "team_home_id"
  has_many :matches_as_away, class_name: "Match", foreign_key: "team_away_id"
end
