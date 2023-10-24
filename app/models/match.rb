# frozen_string_literal: true

class Match < ApplicationRecord
  after_commit :compute_points_commit, on: [:create, :update, :destroy]

  belongs_to :team_home, class_name: "Team"
  belongs_to :team_away, class_name: "Team"

  private
  def compute_points_commit
    Standing.compute(self.team_home)
    Standing.compute(self.team_away)
  end
end
