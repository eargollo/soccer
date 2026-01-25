# frozen_string_literal: true

class ProbabilityCombiner
  def self.call(home_probabilities:, away_probabilities:,
                home_weight: Rails.application.config.probability.combiner_home_weight)
    away_weight = 1.to_d - home_weight

    new(
      home_probabilities: home_probabilities,
      away_probabilities: away_probabilities,
      home_weight: home_weight,
      away_weight: away_weight
    ).call
  end

  def initialize(home_probabilities:, away_probabilities:, home_weight:, away_weight:)
    @home_probabilities = home_probabilities
    @away_probabilities = away_probabilities
    @home_weight = home_weight
    @away_weight = away_weight
  end

  def call
    # Extract probabilities
    h_win, h_draw, = @home_probabilities
    _, a_draw, a_loss = @away_probabilities

    # Apply weighted average formula
    # match_win = (h_win * home_weight + a_loss * away_weight)  # home wins = home team wins OR away team loses
    # match_draw = (h_draw * home_weight + a_draw * away_weight)
    # match_loss = (h_loss * home_weight + a_win * away_weight)  # away wins = home team loses OR away team wins
    match_win = ((h_win * @home_weight) + (a_loss * @away_weight)).round(4)
    match_draw = ((h_draw * @home_weight) + (a_draw * @away_weight)).round(4)
    # Derive one probability from the other two to ensure exact sum = 1.0
    match_loss = (1.to_d - match_win - match_draw).round(4)

    [match_win, match_draw, match_loss]
  end
end
