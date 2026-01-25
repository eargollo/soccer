# frozen_string_literal: true

require "test_helper"

class MatchProbabilityCalculatorTest < ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
  def setup
    @league = leagues(:a_league)
    @season = seasons(:season1)
    @team_home = teams(:barcelona)
    @team_away = teams(:madrid)
    @match = @season.matches.create!(
      team_home: @team_home,
      team_away: @team_away,
      status: 'Not Started'
    )
  end

  test "calculates match probability from existing league team records" do
    # Create or update LeagueTeam records with known probabilities
    home_league_team = LeagueTeam.find_or_initialize_by(league: @league, team: @team_home)
    home_league_team.update!(
      home_prob_win: 0.5.to_d,
      home_prob_draw: 0.3.to_d,
      home_prob_loss: 0.2.to_d,
      away_prob_win: 0.4.to_d,
      away_prob_draw: 0.3.to_d,
      away_prob_loss: 0.3.to_d
    )
    away_league_team = LeagueTeam.find_or_initialize_by(league: @league, team: @team_away)
    away_league_team.update!(
      home_prob_win: 0.6.to_d,
      home_prob_draw: 0.2.to_d,
      home_prob_loss: 0.2.to_d,
      away_prob_win: 0.3.to_d,
      away_prob_draw: 0.3.to_d,
      away_prob_loss: 0.4.to_d
    )

    result = MatchProbabilityCalculator.call(match: @match)

    # Home team home probabilities: [0.5, 0.3, 0.2]
    # Away team away probabilities: [0.3, 0.3, 0.4]
    # Using default 60/40 weights:
    # match_win = 0.5 * 0.6 + 0.4 * 0.4 = 0.3 + 0.16 = 0.46
    # match_draw = 0.3 * 0.6 + 0.3 * 0.4 = 0.18 + 0.12 = 0.30
    # match_loss = 1 - 0.46 - 0.30 = 0.24
    assert_equal 3, result.length
    assert_in_delta 0.46, result[0], 0.0001
    assert_in_delta 0.30, result[1], 0.0001
    assert_in_delta 0.24, result[2], 0.0001
  end

  test "falls back to league baseline when home team league team record doesn't exist" do
    # Destroy home team record if it exists, create only away team record
    LeagueTeam.where(league: @league, team: @team_home).destroy_all
    away_league_team = LeagueTeam.find_or_initialize_by(league: @league, team: @team_away)
    away_league_team.update!(
      home_prob_win: 0.6.to_d,
      home_prob_draw: 0.2.to_d,
      home_prob_loss: 0.2.to_d,
      away_prob_win: 0.3.to_d,
      away_prob_draw: 0.3.to_d,
      away_prob_loss: 0.4.to_d
    )

    # League baseline is [0.45, 0.30, 0.25] (default)
    # Away team away probabilities: [0.3, 0.3, 0.4]
    # Using default 60/40 weights:
    # match_win = 0.45 * 0.6 + 0.4 * 0.4 = 0.27 + 0.16 = 0.43
    # match_draw = 0.30 * 0.6 + 0.3 * 0.4 = 0.18 + 0.12 = 0.30
    # match_loss = 1 - 0.43 - 0.30 = 0.27
    result = MatchProbabilityCalculator.call(match: @match)

    assert_equal 3, result.length
    assert_in_delta 0.43, result[0], 0.0001
    assert_in_delta 0.30, result[1], 0.0001
    assert_in_delta 0.27, result[2], 0.0001
  end

  test "falls back to league baseline when away team league team record doesn't exist" do
    # Destroy away team record if it exists, create only home team record
    LeagueTeam.where(league: @league, team: @team_away).destroy_all
    home_league_team = LeagueTeam.find_or_initialize_by(league: @league, team: @team_home)
    home_league_team.update!(
      home_prob_win: 0.5.to_d,
      home_prob_draw: 0.3.to_d,
      home_prob_loss: 0.2.to_d,
      away_prob_win: 0.4.to_d,
      away_prob_draw: 0.3.to_d,
      away_prob_loss: 0.3.to_d
    )

    # Home team home probabilities: [0.5, 0.3, 0.2]
    # League baseline is [0.45, 0.30, 0.25] (default)
    # For away team, we need to flip the baseline: [0.25, 0.30, 0.45]
    # Using default 60/40 weights:
    # match_win = 0.5 * 0.6 + 0.45 * 0.4 = 0.3 + 0.18 = 0.48
    # match_draw = 0.3 * 0.6 + 0.30 * 0.4 = 0.18 + 0.12 = 0.30
    # match_loss = 1 - 0.48 - 0.30 = 0.22
    result = MatchProbabilityCalculator.call(match: @match)

    assert_equal 3, result.length
    assert_in_delta 0.48, result[0], 0.0001
    assert_in_delta 0.30, result[1], 0.0001
    assert_in_delta 0.22, result[2], 0.0001
  end

  test "falls back to league baseline when both league team records don't exist" do
    # Destroy any existing LeagueTeam records
    LeagueTeam.where(league: @league, team: [@team_home, @team_away]).destroy_all
    # League baseline is [0.45, 0.30, 0.25] (default)
    # For away team, we flip: [0.25, 0.30, 0.45]
    # Using default 60/40 weights:
    # match_win = 0.45 * 0.6 + 0.45 * 0.4 = 0.27 + 0.18 = 0.45
    # match_draw = 0.30 * 0.6 + 0.30 * 0.4 = 0.18 + 0.12 = 0.30
    # match_loss = 1 - 0.45 - 0.30 = 0.25
    result = MatchProbabilityCalculator.call(match: @match)

    assert_equal 3, result.length
    assert_in_delta 0.45, result[0], 0.0001
    assert_in_delta 0.30, result[1], 0.0001
    assert_in_delta 0.25, result[2], 0.0001
  end

  test "allows overriding home weight via parameter" do
    # Create or update LeagueTeam records
    home_league_team = LeagueTeam.find_or_initialize_by(league: @league, team: @team_home)
    home_league_team.update!(
      home_prob_win: 0.5.to_d,
      home_prob_draw: 0.3.to_d,
      home_prob_loss: 0.2.to_d,
      away_prob_win: 0.4.to_d,
      away_prob_draw: 0.3.to_d,
      away_prob_loss: 0.3.to_d
    )
    away_league_team = LeagueTeam.find_or_initialize_by(league: @league, team: @team_away)
    away_league_team.update!(
      home_prob_win: 0.6.to_d,
      home_prob_draw: 0.2.to_d,
      home_prob_loss: 0.2.to_d,
      away_prob_win: 0.3.to_d,
      away_prob_draw: 0.3.to_d,
      away_prob_loss: 0.4.to_d
    )

    # Using 80/20 weights instead of default 60/40:
    # match_win = 0.5 * 0.8 + 0.4 * 0.2 = 0.4 + 0.08 = 0.48
    # match_draw = 0.3 * 0.8 + 0.3 * 0.2 = 0.24 + 0.06 = 0.30
    # match_loss = 1 - 0.48 - 0.30 = 0.22
    result = MatchProbabilityCalculator.call(match: @match, home_weight: 0.8.to_d)

    assert_equal 3, result.length
    assert_in_delta 0.48, result[0], 0.0001
    assert_in_delta 0.30, result[1], 0.0001
    assert_in_delta 0.22, result[2], 0.0001
  end

  test "returns probabilities that sum to exactly 1.0" do
    home_league_team = LeagueTeam.find_or_initialize_by(league: @league, team: @team_home)
    home_league_team.update!(
      home_prob_win: 0.5.to_d,
      home_prob_draw: 0.3.to_d,
      home_prob_loss: 0.2.to_d,
      away_prob_win: 0.4.to_d,
      away_prob_draw: 0.3.to_d,
      away_prob_loss: 0.3.to_d
    )
    away_league_team = LeagueTeam.find_or_initialize_by(league: @league, team: @team_away)
    away_league_team.update!(
      home_prob_win: 0.6.to_d,
      home_prob_draw: 0.2.to_d,
      home_prob_loss: 0.2.to_d,
      away_prob_win: 0.3.to_d,
      away_prob_draw: 0.3.to_d,
      away_prob_loss: 0.4.to_d
    )

    result = MatchProbabilityCalculator.call(match: @match)
    sum = result[0] + result[1] + result[2]

    assert_equal 1.0.to_d, sum
  end

  test "returns BigDecimal values" do
    home_league_team = LeagueTeam.find_or_initialize_by(league: @league, team: @team_home)
    home_league_team.update!(
      home_prob_win: 0.5.to_d,
      home_prob_draw: 0.3.to_d,
      home_prob_loss: 0.2.to_d,
      away_prob_win: 0.4.to_d,
      away_prob_draw: 0.3.to_d,
      away_prob_loss: 0.3.to_d
    )
    away_league_team = LeagueTeam.find_or_initialize_by(league: @league, team: @team_away)
    away_league_team.update!(
      home_prob_win: 0.6.to_d,
      home_prob_draw: 0.2.to_d,
      home_prob_loss: 0.2.to_d,
      away_prob_win: 0.3.to_d,
      away_prob_draw: 0.3.to_d,
      away_prob_loss: 0.4.to_d
    )

    result = MatchProbabilityCalculator.call(match: @match)

    assert_instance_of BigDecimal, result[0]
    assert_instance_of BigDecimal, result[1]
    assert_instance_of BigDecimal, result[2]
  end
end
