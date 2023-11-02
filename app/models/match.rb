# frozen_string_literal: true

class Match < ApplicationRecord
  belongs_to :team_home, class_name: 'Team'
  belongs_to :team_away, class_name: 'Team'

  scope :pending, -> { where.not(status: 'finished') }
  scope :finished, -> { where(status: 'finished') }
  scope :won_home, -> { finished.where(result: 'home') }
  scope :won_away, -> { finished.where(result: 'away') }
  scope :draw, -> { finished.where(result: 'draw') }
  scope :played, -> { where(date: ...Time.zone.now) }

  before_save :determine_result, if: :finished?

  # Need to consider adding a job for doing this computation
  # Rignt now if the computation fails, the next added match will correct it
  # As a job, it is possible to guarantee computation as well as to
  # avoid multiple jobs for the same team in the queue. There is no need
  # to enqueue a team computation if there is one already at the queue.
  after_commit :compute_points_commit, on: %i[create update destroy]

  PROB_WIN = 0.45
  PROB_DRAW = 0.30
  PROB_LOSS = 1 - PROB_WIN - PROB_DRAW

  def finished?
    status == 'finished'
  end

  def prob_win
    probability[0]
  end

  def prob_draw
    probability[1]
  end

  def prob_loss
    probability[2]
  end

  def prob_not_loss
    prob_win + prob_draw
  end

  def probability # rubocop:disable Metrics/AbcSize
    return @probability unless @probability.nil?
    return [PROB_WIN, PROB_DRAW, PROB_LOSS] if team_away.nil? || team_home.nil?

    prob_home = [PROB_WIN, PROB_DRAW, PROB_LOSS]
    if team_home.home_matches.finished.count.positive?
      prob_home[0] = team_home.home_matches.won_home.count.to_f / team_home.home_matches.finished.count
      prob_home[1] = team_home.home_matches.draw.count.to_f / team_home.home_matches.finished.count
      prob_home[2] = team_home.home_matches.won_away.count.to_f / team_home.home_matches.finished.count
    end

    prob_away = [PROB_LOSS, PROB_DRAW, PROB_WIN]
    if team_away.away_matches.finished.count.positive?
      prob_away[0] = team_away.away_matches.won_home.count.to_f / team_away.away_matches.finished.count
      prob_away[1] = team_away.away_matches.draw.count.to_f / team_away.away_matches.finished.count
      prob_away[2] = team_away.away_matches.won_away.count.to_f / team_away.away_matches.finished.count
    end

    @probability = [(PROB_WIN + (4.5 * prob_home[0]) + (4.5 * prob_away[0])) / 10,
                    (PROB_DRAW + (4.5 * prob_home[1]) + (4.5 * prob_away[1])) / 10,
                    (PROB_LOSS + (4.5 * prob_home[2]) + (4.5 * prob_away[2])) / 10]
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
