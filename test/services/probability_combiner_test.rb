# frozen_string_literal: true

require "test_helper"

class ProbabilityCombinerTest < ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
  def setup # rubocop:disable Metrics/AbcSize
    @league = leagues(:a_league)
    @season = seasons(:season1)
    @team_home = teams(:barcelona)
    @team_away = teams(:madrid)

    # Create LeagueTeam records with known probabilities
    @home_league_team = LeagueTeam.create!(
      league: @league,
      team: @team_home,
      home_prob_win: BigDecimal('0.5'),
      home_prob_draw: BigDecimal('0.3'),
      home_prob_loss: BigDecimal('0.2'),
      away_prob_win: BigDecimal('0.4'),
      away_prob_draw: BigDecimal('0.3'),
      away_prob_loss: BigDecimal('0.3')
    )

    @away_league_team = LeagueTeam.create!(
      league: @league,
      team: @team_away,
      home_prob_win: BigDecimal('0.6'),
      home_prob_draw: BigDecimal('0.2'),
      home_prob_loss: BigDecimal('0.2'),
      away_prob_win: BigDecimal('0.3'),
      away_prob_draw: BigDecimal('0.3'),
      away_prob_loss: BigDecimal('0.4')
    )
  end

  test "combines probabilities using weighted average 60/40" do
    # Home team home: [0.5, 0.3, 0.2] (win, draw, loss)
    # Away team away: [0.3, 0.3, 0.4] (win, draw, loss)
    #
    # match_win = (0.5 * 0.6 + 0.4 * 0.4) = 0.3 + 0.16 = 0.46
    # match_draw = (0.3 * 0.6 + 0.3 * 0.4) = 0.18 + 0.12 = 0.30
    # match_loss = (0.2 * 0.6 + 0.3 * 0.4) = 0.12 + 0.12 = 0.24
    # Sum = 1.0

    result = ProbabilityCombiner.call(
      home_probabilities: [@home_league_team.home_prob_win, @home_league_team.home_prob_draw,
                           @home_league_team.home_prob_loss],
      away_probabilities: [@away_league_team.away_prob_win, @away_league_team.away_prob_draw,
                           @away_league_team.away_prob_loss]
    )

    assert_equal 3, result.length
    assert_in_delta BigDecimal('0.46'), result[0], 0.0001  # win
    assert_in_delta BigDecimal('0.30'), result[1], 0.0001  # draw
    assert_in_delta BigDecimal('0.24'), result[2], 0.0001  # loss
  end

  test "returns probabilities that sum to 1.0" do
    result = ProbabilityCombiner.call(
      home_probabilities: [@home_league_team.home_prob_win, @home_league_team.home_prob_draw,
                           @home_league_team.home_prob_loss],
      away_probabilities: [@away_league_team.away_prob_win, @away_league_team.away_prob_draw,
                           @away_league_team.away_prob_loss]
    )

    sum = result[0] + result[1] + result[2]
    assert_equal BigDecimal('1.0'), sum
  end

  test "handles edge case with very high home win probability" do
    # Home team: [0.9, 0.05, 0.05]
    # Away team: [0.1, 0.1, 0.8]
    # match_win = (0.9 * 0.6 + 0.8 * 0.4) = 0.54 + 0.32 = 0.86
    # match_draw = (0.05 * 0.6 + 0.1 * 0.4) = 0.03 + 0.04 = 0.07
    # match_loss = (0.05 * 0.6 + 0.1 * 0.4) = 0.03 + 0.04 = 0.07
    # Sum = 1.0

    result = ProbabilityCombiner.call(
      home_probabilities: [BigDecimal('0.9'), BigDecimal('0.05'), BigDecimal('0.05')],
      away_probabilities: [BigDecimal('0.1'), BigDecimal('0.1'), BigDecimal('0.8')]
    )

    assert_in_delta BigDecimal('0.86'), result[0], 0.0001  # win
    assert_in_delta BigDecimal('0.07'), result[1], 0.0001  # draw
    assert_in_delta BigDecimal('0.07'), result[2], 0.0001  # loss
    sum = result[0] + result[1] + result[2]
    assert_equal BigDecimal('1.0'), sum
  end

  test "handles edge case with very low home win probability" do
    # Home team: [0.1, 0.2, 0.7]
    # Away team: [0.8, 0.1, 0.1]
    # match_win = (0.1 * 0.6 + 0.1 * 0.4) = 0.06 + 0.04 = 0.10
    # match_draw = (0.2 * 0.6 + 0.1 * 0.4) = 0.12 + 0.04 = 0.16
    # match_loss = (0.7 * 0.6 + 0.8 * 0.4) = 0.42 + 0.32 = 0.74
    # Sum = 1.0

    result = ProbabilityCombiner.call(
      home_probabilities: [BigDecimal('0.1'), BigDecimal('0.2'), BigDecimal('0.7')],
      away_probabilities: [BigDecimal('0.8'), BigDecimal('0.1'), BigDecimal('0.1')]
    )

    assert_in_delta BigDecimal('0.10'), result[0], 0.0001  # win
    assert_in_delta BigDecimal('0.16'), result[1], 0.0001  # draw
    assert_in_delta BigDecimal('0.74'), result[2], 0.0001  # loss
    sum = result[0] + result[1] + result[2]
    assert_equal BigDecimal('1.0'), sum
  end

  test "handles equal probabilities" do
    # Both teams have equal probabilities
    # Home team: [0.33, 0.34, 0.33]
    # Away team: [0.33, 0.34, 0.33]
    # match_win = (0.33 * 0.6 + 0.33 * 0.4) = 0.198 + 0.132 = 0.33
    # match_draw = (0.34 * 0.6 + 0.34 * 0.4) = 0.204 + 0.136 = 0.34
    # match_loss = (0.33 * 0.6 + 0.33 * 0.4) = 0.198 + 0.132 = 0.33
    # Sum = 1.0

    result = ProbabilityCombiner.call(
      home_probabilities: [BigDecimal('0.33'), BigDecimal('0.34'), BigDecimal('0.33')],
      away_probabilities: [BigDecimal('0.33'), BigDecimal('0.34'), BigDecimal('0.33')]
    )

    assert_in_delta BigDecimal('0.33'), result[0], 0.0001  # win
    assert_in_delta BigDecimal('0.34'), result[1], 0.0001  # draw
    assert_in_delta BigDecimal('0.33'), result[2], 0.0001  # loss
    sum = result[0] + result[1] + result[2]
    assert_equal BigDecimal('1.0'), sum
  end

  test "uses correct formula: match_win = (h_win * 0.6 + a_loss * 0.4)" do
    # Test the exact formula from design document
    # Home: [0.5, 0.3, 0.2]
    # Away: [0.3, 0.3, 0.4]
    # match_win = 0.5 * 0.6 + 0.4 * 0.4 = 0.3 + 0.16 = 0.46

    result = ProbabilityCombiner.call(
      home_probabilities: [BigDecimal('0.5'), BigDecimal('0.3'), BigDecimal('0.2')],
      away_probabilities: [BigDecimal('0.3'), BigDecimal('0.3'), BigDecimal('0.4')]
    )

    # Verify win probability
    expected_win = (BigDecimal('0.5') * BigDecimal('0.6')) + (BigDecimal('0.4') * BigDecimal('0.4'))
    assert_in_delta expected_win, result[0], 0.0001
  end

  test "uses correct formula: match_draw = (h_draw * 0.6 + a_draw * 0.4)" do
    result = ProbabilityCombiner.call(
      home_probabilities: [BigDecimal('0.5'), BigDecimal('0.3'), BigDecimal('0.2')],
      away_probabilities: [BigDecimal('0.3'), BigDecimal('0.3'), BigDecimal('0.4')]
    )

    # Verify draw probability
    expected_draw = (BigDecimal('0.3') * BigDecimal('0.6')) + (BigDecimal('0.3') * BigDecimal('0.4'))
    assert_in_delta expected_draw, result[1], 0.0001
  end

  test "uses correct formula: match_loss = (h_loss * 0.6 + a_win * 0.4)" do
    result = ProbabilityCombiner.call(
      home_probabilities: [BigDecimal('0.5'), BigDecimal('0.3'), BigDecimal('0.2')],
      away_probabilities: [BigDecimal('0.3'), BigDecimal('0.3'), BigDecimal('0.4')]
    )

    # Verify loss probability
    expected_loss = (BigDecimal('0.2') * BigDecimal('0.6')) + (BigDecimal('0.3') * BigDecimal('0.4'))
    assert_in_delta expected_loss, result[2], 0.0001
  end

  test "returns BigDecimal values" do
    result = ProbabilityCombiner.call(
      home_probabilities: [@home_league_team.home_prob_win, @home_league_team.home_prob_draw,
                           @home_league_team.home_prob_loss],
      away_probabilities: [@away_league_team.away_prob_win, @away_league_team.away_prob_draw,
                           @away_league_team.away_prob_loss]
    )

    assert result[0].is_a?(BigDecimal)
    assert result[1].is_a?(BigDecimal)
    assert result[2].is_a?(BigDecimal)
  end

  test "uses configurable weights from Rails config" do
    # Temporarily change config
    original_home = Rails.application.config.probability.combiner_home_weight

    Rails.application.config.probability.combiner_home_weight = 0.7.to_d
    # away_weight is automatically derived in config/application.rb, but we need to update it here for the test
    Rails.application.config.probability.combiner_away_weight = 0.3.to_d

    result = ProbabilityCombiner.call(
      home_probabilities: [BigDecimal('0.5'), BigDecimal('0.3'), BigDecimal('0.2')],
      away_probabilities: [BigDecimal('0.3'), BigDecimal('0.3'), BigDecimal('0.4')]
    )

    # match_win = (0.5 * 0.7 + 0.4 * 0.3) = 0.35 + 0.12 = 0.47
    assert_in_delta BigDecimal('0.47'), result[0], 0.0001

    # Restore original config
    Rails.application.config.probability.combiner_home_weight = original_home
    Rails.application.config.probability.combiner_away_weight = 1.to_d - original_home
  end

  test "allows overriding home weight via parameter" do
    # Use custom home weight, away weight is automatically derived
    result = ProbabilityCombiner.call(
      home_probabilities: [BigDecimal('0.5'), BigDecimal('0.3'), BigDecimal('0.2')],
      away_probabilities: [BigDecimal('0.3'), BigDecimal('0.3'), BigDecimal('0.4')],
      home_weight: 0.8.to_d
    )

    # match_win = (0.5 * 0.8 + 0.4 * 0.2) = 0.4 + 0.08 = 0.48
    # away_weight is automatically 1 - 0.8 = 0.2
    assert_in_delta BigDecimal('0.48'), result[0], 0.0001
  end
end
