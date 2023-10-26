# frozen_string_literal: true

class Match < ApplicationRecord
  belongs_to :team_home, class_name: 'Team'
  belongs_to :team_away, class_name: 'Team'

  scope :pending, -> { where.not(status: 'finished') }
  scope :finished, -> { where(status: 'finished') }
  scope :won_home, -> { finished.where(result: 'home') }
  scope :won_away, -> { finished.where(result: 'away') }
  scope :draw, -> { finished.where(result: 'draw') }

  before_save :determine_result, if: :finished?

  # Need to consider adding a job for doing this computation
  # Rignt now if the computation fails, the next added match will correct it
  # As a job, it is possible to guarantee computation as well as to
  # avoid multiple jobs for the same team in the queue. There is no need
  # to enqueue a team computation if there is one already at the queue.
  after_commit :compute_points_commit, on: %i[create update destroy]

  def finished?
    status == 'finished'
  end

  private

  def compute_points_commit
    Standing.compute(team_home)
    Standing.compute(team_away)
  end

  def determine_result
    self.result = if home_goals > away_goals
                    'home'
                  elsif home_goals == away_goals
                    'draw'
                  else
                    'away'
                  end
  end
end
