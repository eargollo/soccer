# frozen_string_literal: true

class LeagueBaselineCalculator
  DEFAULT_PROBABILITIES = [0.45.to_d, 0.30.to_d, 0.25.to_d].freeze
  MINIMUM_MATCHES = 500

  def self.call(league:, minimum_matches: MINIMUM_MATCHES)
    new(league: league, minimum_matches: minimum_matches).call
  end

  def initialize(league:, minimum_matches: MINIMUM_MATCHES)
    @league = league
    @minimum_matches = minimum_matches
  end

  def call
    return DEFAULT_PROBABILITIES if finished_matches_count < @minimum_matches

    calculate_from_matches
  end

  private

  def finished_matches_count
    @finished_matches_count ||= @league.matches.finished.count
  end

  def calculate_from_matches # rubocop:disable Metrics/AbcSize
    home_wins = @league.matches.won_home.count
    home_draws = @league.matches.draw.count
    home_losses = @league.matches.won_away.count
    total = home_wins + home_draws + home_losses

    return DEFAULT_PROBABILITIES if total.zero?

    # Use BigDecimal for exact precision (ActiveSupport provides to_d)
    # Calculate two probabilities and derive the third to ensure sum = 1.0
    total_bd = total.to_d
    home_win_prob = (home_wins.to_d / total_bd).round(4)
    home_draw_prob = (home_draws.to_d / total_bd).round(4)
    # Derive home_loss to ensure exact sum of 1.0
    home_loss_prob = (1.to_d - home_win_prob - home_draw_prob).round(4)

    [home_win_prob, home_draw_prob, home_loss_prob]
  end
end
