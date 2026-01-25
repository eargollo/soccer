# frozen_string_literal: true

require "test_helper"

class ProbabilityRecalculatorTest < ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
  def setup
    @league = leagues(:a_league)
    @season = seasons(:season1)
    @team_home = teams(:barcelona)
    @team_away = teams(:madrid)
  end

  test "recalculates probabilities from baseline for a league" do # rubocop:disable Metrics/BlockLength
    # Create some finished matches in chronological order
    match1 = @season.matches.create!(
      team_home: @team_home,
      team_away: @team_away,
      date: 1.day.ago,
      status: 'Not Started'
    )
    match1.update_columns( # rubocop:disable Rails/SkipsModelValidations
      status: 'Match Finished',
      result: 'home',
      home_goals: 2,
      away_goals: 1
    )

    match2 = @season.matches.create!(
      team_home: @team_away,
      team_away: @team_home,
      date: 2.days.ago,
      status: 'Not Started'
    )
    match2.update_columns( # rubocop:disable Rails/SkipsModelValidations
      status: 'Match Finished',
      result: 'draw',
      home_goals: 1,
      away_goals: 1
    )

    # Initialize LeagueTeam records (they'll have baseline probabilities)
    TeamProbabilityInitializer.call(league: @league, team: @team_home)
    TeamProbabilityInitializer.call(league: @league, team: @team_away)

    # Manually update probabilities to some wrong values
    league_team_home = @league.league_teams.find_by(team: @team_home)
    league_team_home.update!(
      home_prob_win: 0.9.to_d,
      home_prob_draw: 0.05.to_d,
      home_prob_loss: 0.05.to_d
    )

    # Recalculate
    ProbabilityRecalculator.call(league: @league)

    # Verify probabilities were recalculated correctly
    league_team_home.reload
    league_team_away = @league.league_teams.find_by(team: @team_away)
    league_team_away.reload

    # Calculate exact expected probabilities
    # Baseline: [0.45, 0.30, 0.25] (home_win, draw, home_loss)
    # Lambda: 0.15 (default)
    #
    # Processing order (chronological, oldest first):
    # 1. match2 (2 days ago): @team_away (home) vs @team_home (away), result: 'draw'
    #    - @team_home away probabilities: start [0.25, 0.30, 0.45] (flipped baseline)
    #      After draw: [0.2125, 0.405, 0.3825]
    #
    # 2. match1 (1 day ago): @team_home (home) vs @team_away (away), result: 'home'
    #    - @team_home home probabilities: start [0.45, 0.30, 0.25]
    #      After home win: [0.5325, 0.255, 0.2125]
    #
    # Expected final values for @team_home:
    expected_home_win = 0.5325.to_d
    expected_home_draw = 0.255.to_d
    expected_home_loss = 0.2125.to_d

    assert_equal expected_home_win, league_team_home.home_prob_win
    assert_equal expected_home_draw, league_team_home.home_prob_draw
    assert_equal expected_home_loss, league_team_home.home_prob_loss

    # For @team_away, after match2 (draw as home):
    # Start: [0.45, 0.30, 0.25]
    # After draw: [0.3825, 0.405, 0.2125]
    expected_away_home_win = 0.3825.to_d
    expected_away_home_draw = 0.405.to_d
    expected_away_home_loss = 0.2125.to_d

    assert_equal expected_away_home_win, league_team_away.home_prob_win
    assert_equal expected_away_home_draw, league_team_away.home_prob_draw
    assert_equal expected_away_home_loss, league_team_away.home_prob_loss
  end

  test "processes matches in chronological order" do # rubocop:disable Metrics/BlockLength
    # Create matches out of chronological order
    match3 = @season.matches.create!(
      team_home: @team_home,
      team_away: @team_away,
      date: 3.days.ago,
      status: 'Not Started'
    )
    match3.update_columns( # rubocop:disable Rails/SkipsModelValidations
      status: 'Match Finished',
      result: 'home',
      home_goals: 1,
      away_goals: 0
    )

    match1 = @season.matches.create!(
      team_home: @team_home,
      team_away: @team_away,
      date: 1.day.ago,
      status: 'Not Started'
    )
    match1.update_columns( # rubocop:disable Rails/SkipsModelValidations
      status: 'Match Finished',
      result: 'away',
      home_goals: 0,
      away_goals: 1
    )

    match2 = @season.matches.create!(
      team_home: @team_away,
      team_away: @team_home,
      date: 2.days.ago,
      status: 'Not Started'
    )
    match2.update_columns( # rubocop:disable Rails/SkipsModelValidations
      status: 'Match Finished',
      result: 'draw',
      home_goals: 1,
      away_goals: 1
    )

    # Initialize
    TeamProbabilityInitializer.call(league: @league, team: @team_home)
    TeamProbabilityInitializer.call(league: @league, team: @team_away)

    # Recalculate
    ProbabilityRecalculator.call(league: @league)

    # Verify matches were processed in order (oldest first)
    league_team_home = @league.league_teams.find_by(team: @team_home)
    league_team_home.reload

    # Calculate exact expected probabilities
    # Baseline: [0.45, 0.30, 0.25] (home_win, draw, home_loss)
    # Lambda: 0.15 (default)
    #
    # Processing order (chronological, oldest first):
    # 1. match3 (3 days ago): @team_home (home) vs @team_away (away), result: 'home'
    #    - Updates @team_home's home probabilities
    #    - Start: [0.45, 0.30, 0.25]
    #    - After home win: [0.5325, 0.255, 0.2125]
    #
    # 2. match2 (2 days ago): @team_away (home) vs @team_home (away), result: 'draw'
    #    - Updates @team_home's away probabilities (not home, so home probs unchanged)
    #
    # 3. match1 (1 day ago): @team_home (home) vs @team_away (away), result: 'away' (home loss)
    #    - Updates @team_home's home probabilities
    #    - Start: [0.5325, 0.255, 0.2125] (from after match3)
    #    - Decay: [0.452625, 0.21675, 0.180625]
    #    - Add lambda to loss: [0.452625, 0.21675, 0.330625]
    #    - Round: [0.4526, 0.2168, 0.3306]
    #
    # Expected final values for @team_home home probabilities:
    expected_home_win = 0.4526.to_d
    expected_home_draw = 0.2168.to_d
    expected_home_loss = 0.3306.to_d

    assert_equal expected_home_win, league_team_home.home_prob_win
    assert_equal expected_home_draw, league_team_home.home_prob_draw
    assert_equal expected_home_loss, league_team_home.home_prob_loss
  end

  test "handles league with no matches" do
    # Create a league with no matches
    empty_league = League.create!(name: "Empty League", reference: 999)
    empty_league.seasons.create!(year: 2024)

    # Initialize a team
    TeamProbabilityInitializer.call(league: empty_league, team: @team_home)

    # Recalculate should not error
    assert_nothing_raised do
      ProbabilityRecalculator.call(league: empty_league)
    end

    # Probabilities should remain at baseline
    league_team = empty_league.league_teams.find_by(team: @team_home)
    baseline = empty_league.baseline
    assert_equal baseline[0], league_team.home_prob_win
    assert_equal baseline[1], league_team.home_prob_draw
    assert_equal baseline[2], league_team.home_prob_loss
  end

  test "handles league with many matches" do # rubocop:disable Metrics/BlockLength
    # Create 100 matches
    100.times do |i|
      match = @season.matches.create!(
        team_home: @team_home,
        team_away: @team_away,
        date: (100 - i).days.ago,
        status: 'Not Started'
      )
      result = case i % 3
               when 0 then 'home'
               when 1 then 'draw'
               else 'away'
               end
      match.update_columns( # rubocop:disable Rails/SkipsModelValidations
        status: 'Match Finished',
        result: result,
        home_goals: (if result == 'home'
                       1
                     else
                       (result == 'draw' ? 1 : 0)
                     end),
        away_goals: (if result == 'away'
                       1
                     else
                       (result == 'draw' ? 1 : 0)
                     end)
      )
    end

    # Initialize
    TeamProbabilityInitializer.call(league: @league, team: @team_home)
    TeamProbabilityInitializer.call(league: @league, team: @team_away)

    # Recalculate should complete without error
    assert_nothing_raised do
      ProbabilityRecalculator.call(league: @league)
    end

    # Verify probabilities are valid and match expected values
    # With 100 matches cycling: 34 home wins, 33 draws, 33 away wins
    # After processing all matches with EMA (lambda=0.15), we can calculate exact final probabilities
    league_team_home = @league.league_teams.find_by(team: @team_home)
    league_team_home.reload

    # Calculate expected probabilities after 100 matches
    # Starting from baseline [0.45, 0.30, 0.25]
    # After 34 home wins, 33 draws, 33 away wins (home losses)
    # Using EMA formula iteratively
    baseline = [0.45.to_d, 0.30.to_d, 0.25.to_d]
    lambda = 0.15.to_d
    probs = baseline.dup

    100.times do |i|
      result = case i % 3
               when 0 then 0 # home win
               when 1 then 1 # draw
               else 2 # away win (home loss)
               end
      # Decay all probabilities
      probs.map! { |p| p * (1.to_d - lambda) }
      # Add lambda to the result
      probs[result] += lambda
      # Round win and draw, derive loss
      probs[0] = probs[0].round(4)
      probs[1] = probs[1].round(4)
      probs[2] = (1.to_d - probs[0] - probs[1]).round(4)
    end

    expected_win = probs[0]
    expected_draw = probs[1]
    expected_loss = probs[2]

    assert_equal expected_win, league_team_home.home_prob_win
    assert_equal expected_draw, league_team_home.home_prob_draw
    assert_equal expected_loss, league_team_home.home_prob_loss
  end

  test "allows overriding lambda parameter" do
    # Create a match
    match = @season.matches.create!(
      team_home: @team_home,
      team_away: @team_away,
      date: 1.day.ago,
      status: 'Not Started'
    )
    match.update_columns( # rubocop:disable Rails/SkipsModelValidations
      status: 'Match Finished',
      result: 'home',
      home_goals: 1,
      away_goals: 0
    )

    # Initialize
    TeamProbabilityInitializer.call(league: @league, team: @team_home)

    # Recalculate with custom lambda
    ProbabilityRecalculator.call(league: @league, lambda: 0.3.to_d)

    # Recalculate again with different lambda (resets to baseline first)
    ProbabilityRecalculator.call(league: @league, lambda: 0.1.to_d)

    # Calculate exact expected probabilities
    # Baseline: [0.45, 0.30, 0.25]
    # After recalculation with lambda=0.1 and match result 'home':
    # Decay: [0.405, 0.27, 0.225]
    # Add lambda to win: [0.505, 0.27, 0.225]
    # Round and derive: [0.505, 0.27, 0.225]
    league_team = @league.league_teams.find_by(team: @team_home)
    league_team.reload

    expected_win = 0.505.to_d
    expected_draw = 0.27.to_d
    expected_loss = 0.225.to_d

    assert_equal expected_win, league_team.home_prob_win
    assert_equal expected_draw, league_team.home_prob_draw
    assert_equal expected_loss, league_team.home_prob_loss
  end

  test "recalculates for specific team when team parameter provided" do # rubocop:disable Metrics/BlockLength
    team3 = teams(:espanyol)

    # Create matches for different teams
    match1 = @season.matches.create!(
      team_home: @team_home,
      team_away: @team_away,
      date: 1.day.ago,
      status: 'Not Started'
    )
    match1.update_columns( # rubocop:disable Rails/SkipsModelValidations
      status: 'Match Finished',
      result: 'home',
      home_goals: 1,
      away_goals: 0
    )

    match2 = @season.matches.create!(
      team_home: @team_home,
      team_away: team3,
      date: 2.days.ago,
      status: 'Not Started'
    )
    match2.update_columns( # rubocop:disable Rails/SkipsModelValidations
      status: 'Match Finished',
      result: 'home',
      home_goals: 2,
      away_goals: 0
    )

    # Initialize all teams
    TeamProbabilityInitializer.call(league: @league, team: @team_home)
    TeamProbabilityInitializer.call(league: @league, team: @team_away)
    TeamProbabilityInitializer.call(league: @league, team: team3)

    # Manually set wrong probabilities for team3
    league_team3 = @league.league_teams.find_by(team: team3)
    original_prob = league_team3.home_prob_win

    # Recalculate only for @team_home
    ProbabilityRecalculator.call(league: @league, team: @team_home)

    # team3's probabilities should not have changed
    league_team3.reload
    assert_equal original_prob, league_team3.home_prob_win

    # Calculate exact expected probabilities for @team_home
    # Baseline: [0.45, 0.30, 0.25]
    # Processing order (chronological, oldest first):
    # 1. match2 (2 days ago): @team_home (home) vs team3 (away), result: 'home'
    #    - After home win: [0.5325, 0.255, 0.2125]
    # 2. match1 (1 day ago): @team_home (home) vs @team_away (away), result: 'home'
    #    - After home win: [0.6026, 0.2168, 0.1806]
    league_team_home = @league.league_teams.find_by(team: @team_home)
    league_team_home.reload

    expected_win = 0.6026.to_d
    expected_draw = 0.2168.to_d
    expected_loss = 0.1806.to_d

    assert_equal expected_win, league_team_home.home_prob_win
    assert_equal expected_draw, league_team_home.home_prob_draw
    assert_equal expected_loss, league_team_home.home_prob_loss
  end
end
