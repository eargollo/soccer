class Match < ApplicationRecord
  belongs_to :team_home, class_name: "Team"
  belongs_to :team_away, class_name: "Team"

  before_save :determine_result, if: :finished?

  # Need to consider adding a job for doing this computation
  # Rignt now if the computation fails, the next added match will correct it
  # As a job, it is possible to guarantee computation as well as to
  # avoid multiple jobs for the same team in the queue. There is no need
  # to enqueue a team computation if there is one already at the queue.
  after_commit :compute_points_commit, on: [:create, :update, :destroy]

  def finished?
    self.status == "finished"
  end

  scope :pending, -> { where.not(status: "finished }

  private
  def compute_points_commit
    Standing.compute(self.team_home)
    Standing.compute(self.team_away)
  end

  def determine_result
    if self.home_goals > self.away_goals
      self.result = "home"
    else
      if self.home_goals == self.away_goals
        self.result = "draw"
      else
        self.result = "away"
      end
    end
  end
end
