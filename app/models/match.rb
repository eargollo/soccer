# frozen_string_literal: true

# == Schema Information
#
# Table name: matches
#
#  id           :bigint           not null, primary key
#  away_goals   :integer
#  date         :datetime
#  home_goals   :integer
#  reference    :integer
#  result       :string
#  round        :integer
#  round_name   :string
#  status       :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  season_id    :bigint           default(1), not null
#  team_away_id :bigint           not null
#  team_home_id :bigint           not null
#
# Indexes
#
#  index_matches_on_season_id     (season_id)
#  index_matches_on_team_away_id  (team_away_id)
#  index_matches_on_team_home_id  (team_home_id)
#
# Foreign Keys
#
#  fk_rails_...  (season_id => seasons.id)
#  fk_rails_...  (team_away_id => teams.id)
#  fk_rails_...  (team_home_id => teams.id)
#
class Match < ApplicationRecord
  belongs_to :team_home, class_name: 'Team'
  belongs_to :team_away, class_name: 'Team'
  belongs_to :season
  has_one :league, through: :season

  scope :pending, -> { where.not(status: 'Match Finished') }
  scope :scheduled, -> { where.not(status: ['Match Postponed', 'Match Finished', 'Time To Be Defined']) }
  scope :finished, -> { where(status: 'Match Finished') }
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
    status == 'Match Finished'
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

  # Returns historical statistics for the same teams in the same league
  # with the same home/away context (excluding current match)
  # Returns hash with :wins, :draws, :losses (from home team's perspective)
  def historical_stats
    return @historical_stats if defined?(@historical_stats)

    # Find all finished matches in the same league with same teams and home/away context
    historical_matches = league.matches.finished
                               .where(team_home: team_home, team_away: team_away)
                               .where.not(id: id)

    @historical_stats = {
      wins: historical_matches.where(result: 'home').count,
      draws: historical_matches.where(result: 'draw').count,
      losses: historical_matches.where(result: 'away').count
    }
  end

  def probability # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    return @probability unless @probability.nil?
    return [PROB_WIN, PROB_DRAW, PROB_LOSS] if team_away.nil? || team_home.nil?

    # Match probability calculation:
    weights = [25, 25, 25, 25]
    # League all matches: 5 (league matches >= 500)
    # Team at league Home/Away: 15 (team matches at league > 80)
    # Team last 50 at league Home/Away: 30
    # Team last 15 at leagye Home/Away: 50

    prob_home = [
      league.probability.collect { |n| n * weights[0] },
      league.team_home_probability(team: team_home, minimum: 80).collect { |n| n * weights[1] },
      league.team_home_probability(team: team_home, limit: 50, minimum: 50).collect { |n| n * weights[2] },
      league.team_home_probability(team: team_home, limit: 15, minimum: 15).collect { |n| n * weights[3] }
    ].transpose.map { |x| x.reduce(:+) } # rubocop:disable Performance/Sum

    prob_away = [
      league.probability.collect { |n| n * weights[0] },
      league.team_away_probability(team: team_away, minimum: 80).collect { |n| n * weights[1] },
      league.team_away_probability(team: team_away, limit: 50, minimum: 50).collect { |n| n * weights[2] },
      league.team_away_probability(team: team_away, limit: 15, minimum: 15).collect { |n| n * weights[3] }
    ].transpose.map { |x| x.reduce(:+) } # rubocop:disable Performance/Sum

    @probability = [prob_home, prob_away].transpose.map { |x| x.reduce(:+) }.collect { |n| n / 200 } # rubocop:disable Performance/Sum
  end

  private

  def compute_points_commit
    Standing.compute(season:, team: team_home)
    Standing.compute(season:, team: team_away)
    LeagueStanding.refresh
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
