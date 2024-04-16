# frozen_string_literal: true

class Match < ApplicationRecord
  belongs_to :team_home, class_name: 'Team'
  belongs_to :team_away, class_name: 'Team'
  belongs_to :season
  has_one :league, through: :season

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

  def probability # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    return @probability unless @probability.nil?
    return [PROB_WIN, PROB_DRAW, PROB_LOSS] if team_away.nil? || team_home.nil?

    # Match probability calculation:
    # League all matches: 5 (league matches >= 500)
    # Team at league Home/Away: 15 (team matches at league > 80)
    # Team last 50 at league Home/Away: 30
    # Team last 15 at leagye Home/Away: 50

    prob_home = [
      league.probability.collect { |n| n * 5 },
      league.team_home_probability(team: team_home, minimum: 80).collect { |n| n * 15 },
      league.team_home_probability(team: team_home, limit: 50, minimum: 50).collect { |n| n * 30 },
      league.team_home_probability(team: team_home, limit: 15, minimum: 15).collect { |n| n * 50 }
    ].transpose.map { |x| x.reduce(:+) }

    prob_away = [ league.probability.collect { |n| n * 5 },
                  league.team_away_probability(team: team_away, minimum: 80).collect { |n| n * 15 },
                  league.team_away_probability(team: team_away, limit: 50, minimum: 50).collect { |n| n * 30 },
                  league.team_away_probability(team: team_away, limit: 15, minimum: 15).collect { |n| n * 50 }
              ].transpose.map {|x| x.reduce(:+)}

    @probability = [prob_home, prob_away].transpose.map {|x| x.reduce(:+)}.collect { |n| n / 200 }
  end

  private

  def compute_points_commit
    Standing.compute(season:, team: team_home)
    Standing.compute(season:, team: team_away)
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
