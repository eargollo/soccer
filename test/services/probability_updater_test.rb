# frozen_string_literal: true

require "test_helper"

class ProbabilityUpdaterTest < ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
  # Helper to create a finished match without triggering callbacks
  def create_finished_match(result:, home_goals:, away_goals:)
    match = @season.matches.create!(
      team_home: @team_home,
      team_away: @team_away,
      status: 'Not Started'
    )
    match.update_columns( # rubocop:disable Rails/SkipsModelValidations
      status: 'Match Finished',
      result: result,
      home_goals: home_goals,
      away_goals: away_goals
    )
    match.reload
  end

  def setup # rubocop:disable Metrics/AbcSize
    @league = leagues(:a_league)
    @season = seasons(:season1)
    @team_home = teams(:barcelona)
    @team_away = teams(:madrid)

    # Initialize LeagueTeam records with baseline probabilities
    @home_league_team = LeagueTeam.create!(
      league: @league,
      team: @team_home,
      home_prob_win: BigDecimal('0.47'),
      home_prob_draw: BigDecimal('0.23'),
      home_prob_loss: BigDecimal('0.30'),
      away_prob_win: BigDecimal('0.30'),
      away_prob_draw: BigDecimal('0.23'),
      away_prob_loss: BigDecimal('0.47')
    )

    @away_league_team = LeagueTeam.create!(
      league: @league,
      team: @team_away,
      home_prob_win: BigDecimal('0.47'),
      home_prob_draw: BigDecimal('0.23'),
      home_prob_loss: BigDecimal('0.30'),
      away_prob_win: BigDecimal('0.30'),
      away_prob_draw: BigDecimal('0.23'),
      away_prob_loss: BigDecimal('0.47')
    )
  end

  test "updates home team home probability when home wins" do
    # Create match without triggering callback
    match = create_finished_match(result: 'home', home_goals: 2, away_goals: 1)
    ProbabilityUpdater.call(match: match)
    @home_league_team.reload
    # home_win = 0.47 * 0.85 + 0.15 = 0.5495
    # draw = 0.23 * 0.85 = 0.1955
    # home_loss = 0.30 * 0.85 = 0.255
    # Sum = 1.0, so no normalization needed
    assert_in_delta BigDecimal('0.5495'), @home_league_team.home_prob_win, 0.0001
    assert_in_delta BigDecimal('0.1955'), @home_league_team.home_prob_draw, 0.0001
    assert_in_delta BigDecimal('0.255'), @home_league_team.home_prob_loss, 0.0001
  end

  test "updates home team home probability when draw" do
    match = create_finished_match(result: 'draw', home_goals: 1, away_goals: 1)
    ProbabilityUpdater.call(match: match)

    @home_league_team.reload
    # home_win = 0.47 * 0.85 = 0.3995
    # draw = 0.23 * 0.85 + 0.15 = 0.3455
    # home_loss = 0.30 * 0.85 = 0.255
    # Sum = 1.0, so no normalization needed
    assert_in_delta BigDecimal('0.3995'), @home_league_team.home_prob_win, 0.0001
    assert_in_delta BigDecimal('0.3455'), @home_league_team.home_prob_draw, 0.0001
    assert_in_delta BigDecimal('0.255'), @home_league_team.home_prob_loss, 0.0001
  end

  test "updates home team home probability when away wins" do
    match = create_finished_match(result: 'away', home_goals: 0, away_goals: 1)
    ProbabilityUpdater.call(match: match)

    @home_league_team.reload
    # home_win = 0.47 * 0.85 = 0.3995
    # draw = 0.23 * 0.85 = 0.1955
    # home_loss = 0.30 * 0.85 + 0.15 = 0.405
    # Sum = 1.0, so no normalization needed
    assert_in_delta BigDecimal('0.3995'), @home_league_team.home_prob_win, 0.0001
    assert_in_delta BigDecimal('0.1955'), @home_league_team.home_prob_draw, 0.0001
    assert_in_delta BigDecimal('0.405'), @home_league_team.home_prob_loss, 0.0001
  end

  test "updates away team away probability when home wins" do
    match = create_finished_match(result: 'home', home_goals: 2, away_goals: 1)
    ProbabilityUpdater.call(match: match)

    @away_league_team.reload
    # When home wins, away loses
    # away_win = 0.30 * 0.85 = 0.255
    # away_draw = 0.23 * 0.85 = 0.1955
    # away_loss = 0.47 * 0.85 + 0.15 = 0.5495
    assert_in_delta BigDecimal('0.255'), @away_league_team.away_prob_win, 0.0001
    assert_in_delta BigDecimal('0.1955'), @away_league_team.away_prob_draw, 0.0001
    assert_in_delta BigDecimal('0.5495'), @away_league_team.away_prob_loss, 0.0001
  end

  test "updates away team away probability when draw" do
    match = create_finished_match(result: 'draw', home_goals: 1, away_goals: 1)
    ProbabilityUpdater.call(match: match)

    @away_league_team.reload
    # When draw, away also draws
    # away_win = 0.30 * 0.85 = 0.255
    # away_draw = 0.23 * 0.85 + 0.15 = 0.3455
    # away_loss = 0.47 * 0.85 = 0.3995
    assert_in_delta BigDecimal('0.255'), @away_league_team.away_prob_win, 0.0001
    assert_in_delta BigDecimal('0.3455'), @away_league_team.away_prob_draw, 0.0001
    assert_in_delta BigDecimal('0.3995'), @away_league_team.away_prob_loss, 0.0001
  end

  test "updates away team away probability when away wins" do
    match = create_finished_match(result: 'away', home_goals: 0, away_goals: 1)
    ProbabilityUpdater.call(match: match)

    @away_league_team.reload
    # When away wins, away wins
    # away_win = 0.30 * 0.85 + 0.15 = 0.405
    # away_draw = 0.23 * 0.85 = 0.1955
    # away_loss = 0.47 * 0.85 = 0.3995
    assert_in_delta BigDecimal('0.405'), @away_league_team.away_prob_win, 0.0001
    assert_in_delta BigDecimal('0.1955'), @away_league_team.away_prob_draw, 0.0001
    assert_in_delta BigDecimal('0.3995'), @away_league_team.away_prob_loss, 0.0001
  end

  test "normalizes probabilities to sum to 1.0" do
    # Set probabilities that don't sum to 1.0 after update
    @home_league_team.update!(
      home_prob_win: BigDecimal('0.5'),
      home_prob_draw: BigDecimal('0.3'),
      home_prob_loss: BigDecimal('0.2')
    )

    match = create_finished_match(result: 'home', home_goals: 2, away_goals: 1)
    ProbabilityUpdater.call(match: match)

    @home_league_team.reload
    sum = @home_league_team.home_prob_win + @home_league_team.home_prob_draw + @home_league_team.home_prob_loss
    assert_equal BigDecimal('1.0'), sum
  end

  test "does not update if match is not finished" do
    original_win = @home_league_team.home_prob_win

    match = @season.matches.create!(
      team_home: @team_home,
      team_away: @team_away,
      status: 'Not Started'
    )

    ProbabilityUpdater.call(match: match)

    @home_league_team.reload
    assert_equal original_win, @home_league_team.home_prob_win
  end

  test "initializes league team records if they don't exist" do
    LeagueTeam.where(league: @league, team: [@team_home, @team_away]).destroy_all

    match = create_finished_match(result: 'home', home_goals: 2, away_goals: 1)
    ProbabilityUpdater.call(match: match)

    # Should create LeagueTeam records
    assert LeagueTeam.exists?(league: @league, team: @team_home)
    assert LeagueTeam.exists?(league: @league, team: @team_away)
  end

  test "uses configurable lambda from Rails config" do
    # Test with exact calculation to verify lambda
    # Starting with 0.5, 0.3, 0.2
    @home_league_team.update!(
      home_prob_win: BigDecimal('0.5'),
      home_prob_draw: BigDecimal('0.3'),
      home_prob_loss: BigDecimal('0.2')
    )

    match = create_finished_match(result: 'home', home_goals: 2, away_goals: 1)
    ProbabilityUpdater.call(match: match)

    @home_league_team.reload
    # home_win = 0.5 * 0.85 + 0.15 = 0.575
    # draw = 0.3 * 0.85 = 0.255
    # home_loss = 0.2 * 0.85 = 0.17
    # Sum = 1.0, so no normalization needed
    assert_equal BigDecimal('0.575'), @home_league_team.home_prob_win
    assert_equal BigDecimal('0.255'), @home_league_team.home_prob_draw
    assert_equal BigDecimal('0.17'), @home_league_team.home_prob_loss
  end

  test "allows overriding lambda via parameter" do
    # Test with custom lambda value
    @home_league_team.update!(
      home_prob_win: BigDecimal('0.5'),
      home_prob_draw: BigDecimal('0.3'),
      home_prob_loss: BigDecimal('0.2')
    )

    # Create match without triggering callback
    match = create_finished_match(result: 'home', home_goals: 2, away_goals: 1)

    # Use custom lambda of 0.2 instead of default 0.15
    ProbabilityUpdater.call(match: match, lambda: 0.2.to_d)
    @home_league_team.reload
    # home_win = 0.5 * 0.8 + 0.2 = 0.6
    # draw = 0.3 * 0.8 = 0.24
    # home_loss = 0.2 * 0.8 = 0.16
    # After rounding and deriving loss: win=0.6, draw=0.24, loss=1-0.6-0.24=0.16
    assert_in_delta BigDecimal('0.6'), @home_league_team.home_prob_win, 0.0001
    assert_in_delta BigDecimal('0.24'), @home_league_team.home_prob_draw, 0.0001
    assert_in_delta BigDecimal('0.16'), @home_league_team.home_prob_loss, 0.0001
  end

  test "multiple sequential updates work correctly" do # rubocop:disable Metrics/BlockLength
    # Start with baseline probabilities
    @home_league_team.update!(
      home_prob_win: BigDecimal('0.47'),
      home_prob_draw: BigDecimal('0.23'),
      home_prob_loss: BigDecimal('0.30')
    )

    # First match: home wins
    match1 = create_finished_match(result: 'home', home_goals: 2, away_goals: 1)
    ProbabilityUpdater.call(match: match1)

    @home_league_team.reload
    # After first match (home win):
    # home_win = 0.47 * 0.85 + 0.15 = 0.5495
    # draw = 0.23 * 0.85 = 0.1955
    # home_loss = 0.30 * 0.85 = 0.255
    assert_in_delta BigDecimal('0.5495'), @home_league_team.home_prob_win, 0.0001
    assert_in_delta BigDecimal('0.1955'), @home_league_team.home_prob_draw, 0.0001
    assert_in_delta BigDecimal('0.255'), @home_league_team.home_prob_loss, 0.0001

    # Second match: draw
    team2 = teams(:espanyol)
    match2 = @season.matches.create!(
      team_home: @team_home,
      team_away: team2,
      status: 'Not Started',
      date: Time.current
    )
    match2.update_columns( # rubocop:disable Rails/SkipsModelValidations
      status: 'Match Finished',
      result: 'draw',
      home_goals: 1,
      away_goals: 1
    )
    ProbabilityUpdater.call(match: match2.reload)

    @home_league_team.reload
    # After second match (draw):
    # home_win = 0.5495 * 0.85 = 0.467075
    # draw = 0.1955 * 0.85 + 0.15 = 0.316175
    # home_loss = 0.255 * 0.85 = 0.21675
    # Sum = 1.0, derive loss: 1.0 - 0.467075 - 0.316175 = 0.21675
    assert_in_delta BigDecimal('0.4671'), @home_league_team.home_prob_win, 0.0001
    assert_in_delta BigDecimal('0.3162'), @home_league_team.home_prob_draw, 0.0001
    assert_in_delta BigDecimal('0.2167'), @home_league_team.home_prob_loss, 0.0001

    # Verify sum is exactly 1.0
    sum = @home_league_team.home_prob_win + @home_league_team.home_prob_draw + @home_league_team.home_prob_loss
    assert_equal BigDecimal('1.0'), sum
  end

  test "handles very high win probability" do
    # Edge case: team with very high win probability (0.9, 0.05, 0.05)
    @home_league_team.update!(
      home_prob_win: BigDecimal('0.9'),
      home_prob_draw: BigDecimal('0.05'),
      home_prob_loss: BigDecimal('0.05')
    )

    match = create_finished_match(result: 'home', home_goals: 2, away_goals: 1)
    ProbabilityUpdater.call(match: match)

    @home_league_team.reload
    # After home win with high initial probability:
    # home_win = 0.9 * 0.85 + 0.15 = 0.915
    # draw = 0.05 * 0.85 = 0.0425
    # home_loss = 0.05 * 0.85 = 0.0425
    # Derive loss: 1.0 - 0.915 - 0.0425 = 0.0425
    assert_in_delta BigDecimal('0.915'), @home_league_team.home_prob_win, 0.0001
    assert_in_delta BigDecimal('0.0425'), @home_league_team.home_prob_draw, 0.0001
    assert_in_delta BigDecimal('0.0425'), @home_league_team.home_prob_loss, 0.0001

    sum = @home_league_team.home_prob_win + @home_league_team.home_prob_draw + @home_league_team.home_prob_loss
    assert_equal BigDecimal('1.0'), sum
  end

  test "handles very low win probability" do
    # Edge case: team with very low win probability (0.1, 0.2, 0.7)
    @home_league_team.update!(
      home_prob_win: BigDecimal('0.1'),
      home_prob_draw: BigDecimal('0.2'),
      home_prob_loss: BigDecimal('0.7')
    )

    match = create_finished_match(result: 'home', home_goals: 2, away_goals: 1)
    ProbabilityUpdater.call(match: match)

    @home_league_team.reload
    # After home win with low initial probability:
    # home_win = 0.1 * 0.85 + 0.15 = 0.235
    # draw = 0.2 * 0.85 = 0.17
    # home_loss = 0.7 * 0.85 = 0.595
    # Derive loss: 1.0 - 0.235 - 0.17 = 0.595
    assert_in_delta BigDecimal('0.235'), @home_league_team.home_prob_win, 0.0001
    assert_in_delta BigDecimal('0.17'), @home_league_team.home_prob_draw, 0.0001
    assert_in_delta BigDecimal('0.595'), @home_league_team.home_prob_loss, 0.0001

    sum = @home_league_team.home_prob_win + @home_league_team.home_prob_draw + @home_league_team.home_prob_loss
    assert_equal BigDecimal('1.0'), sum
  end

  test "handles loss after very high win probability" do
    # Edge case: team with high win probability loses
    @home_league_team.update!(
      home_prob_win: BigDecimal('0.9'),
      home_prob_draw: BigDecimal('0.05'),
      home_prob_loss: BigDecimal('0.05')
    )

    match = create_finished_match(result: 'away', home_goals: 0, away_goals: 1)
    ProbabilityUpdater.call(match: match)

    @home_league_team.reload
    # After home loss with high initial win probability:
    # home_win = 0.9 * 0.85 = 0.765
    # draw = 0.05 * 0.85 = 0.0425
    # home_loss = 0.05 * 0.85 + 0.15 = 0.1925
    # Derive loss: 1.0 - 0.765 - 0.0425 = 0.1925
    assert_in_delta BigDecimal('0.765'), @home_league_team.home_prob_win, 0.0001
    assert_in_delta BigDecimal('0.0425'), @home_league_team.home_prob_draw, 0.0001
    assert_in_delta BigDecimal('0.1925'), @home_league_team.home_prob_loss, 0.0001

    sum = @home_league_team.home_prob_win + @home_league_team.home_prob_draw + @home_league_team.home_prob_loss
    assert_equal BigDecimal('1.0'), sum
  end

  test "handles win after very low win probability" do
    # Edge case: team with low win probability wins
    @home_league_team.update!(
      home_prob_win: BigDecimal('0.1'),
      home_prob_draw: BigDecimal('0.2'),
      home_prob_loss: BigDecimal('0.7')
    )

    match = create_finished_match(result: 'home', home_goals: 2, away_goals: 1)
    ProbabilityUpdater.call(match: match)

    @home_league_team.reload
    # After home win with low initial win probability:
    # home_win = 0.1 * 0.85 + 0.15 = 0.235
    # draw = 0.2 * 0.85 = 0.17
    # home_loss = 0.7 * 0.85 = 0.595
    # Derive loss: 1.0 - 0.235 - 0.17 = 0.595
    assert_in_delta BigDecimal('0.235'), @home_league_team.home_prob_win, 0.0001
    assert_in_delta BigDecimal('0.17'), @home_league_team.home_prob_draw, 0.0001
    assert_in_delta BigDecimal('0.595'), @home_league_team.home_prob_loss, 0.0001

    sum = @home_league_team.home_prob_win + @home_league_team.home_prob_draw + @home_league_team.home_prob_loss
    assert_equal BigDecimal('1.0'), sum
  end

  test "example calculation matches expected results from design document" do
    # Example from design document:
    # Initial: [47%, 23%, 30%] (home_win, draw, home_loss)
    # Match result: Home win
    # Expected after: [54.95%, 19.55%, 25.5%]
    @home_league_team.update!(
      home_prob_win: BigDecimal('0.47'),
      home_prob_draw: BigDecimal('0.23'),
      home_prob_loss: BigDecimal('0.30')
    )

    match = create_finished_match(result: 'home', home_goals: 2, away_goals: 1)
    ProbabilityUpdater.call(match: match)

    @home_league_team.reload
    # Verify exact values from design document example
    assert_in_delta BigDecimal('0.5495'), @home_league_team.home_prob_win, 0.0001
    assert_in_delta BigDecimal('0.1955'), @home_league_team.home_prob_draw, 0.0001
    assert_in_delta BigDecimal('0.255'), @home_league_team.home_prob_loss, 0.0001
  end
end
