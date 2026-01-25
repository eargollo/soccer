# frozen_string_literal: true

require "test_helper"

class LeagueBaselineCalculatorTest < ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
  def setup
    @league = leagues(:a_league)
    @season = seasons(:season1)
    @team_home = teams(:barcelona)
    @team_away = teams(:madrid)
  end

  test "calculates correct percentages from league matches" do # rubocop:disable Metrics/BlockLength
    # Create finished matches with known results
    @season.matches.create!(
      team_home: @team_home,
      team_away: @team_away,
      status: 'Match Finished',
      result: 'home',
      home_goals: 2,
      away_goals: 1
    )
    @season.matches.create!(
      team_home: @team_away,
      team_away: @team_home,
      status: 'Match Finished',
      result: 'draw',
      home_goals: 1,
      away_goals: 1
    )
    @season.matches.create!(
      team_home: @team_home,
      team_away: @team_away,
      status: 'Match Finished',
      result: 'away',
      home_goals: 0,
      away_goals: 1
    )

    # 1 home win, 1 draw, 1 away win (which is home loss)
    # Total: 3 matches
    # home_win: 1/3 = 0.3333... → rounds to 0.3333
    # draw: 1/3 = 0.3333... → rounds to 0.3333
    # home_loss: 1 - 0.3333 - 0.3333 = 0.3334 (derived to ensure sum = 1.0)
    # Use minimum_matches: 0 to bypass the 500 threshold for testing
    result = LeagueBaselineCalculator.call(league: @league, minimum_matches: 0)

    assert_equal 3, result.length
    assert_equal BigDecimal('0.3333'), result[0] # home_win
    assert_equal BigDecimal('0.3333'), result[1] # draw
    assert_equal BigDecimal('0.3334'), result[2] # home_loss (derived)
  end

  test "returns default probabilities when league has less than 500 matches" do
    # League has no matches or very few
    # Uses default minimum_matches: 500
    result = LeagueBaselineCalculator.call(league: @league)

    assert_equal [0.45.to_d, 0.30.to_d, 0.25.to_d], result
  end

  test "returns default probabilities when league has no matches" do
    new_league = League.create!(name: "New League", reference: 999)
    # Uses default minimum_matches: 500
    result = LeagueBaselineCalculator.call(league: new_league)

    assert_equal [0.45.to_d, 0.30.to_d, 0.25.to_d], result
  end

  test "handles league with only home wins" do
    # Create matches all with home wins
    10.times do
      @season.matches.create!(
        team_home: @team_home,
        team_away: @team_away,
        status: 'Match Finished',
        result: 'home',
        home_goals: 1,
        away_goals: 0
      )
    end

    result = LeagueBaselineCalculator.call(league: @league, minimum_matches: 0)

    assert_equal 3, result.length
    assert_equal 1.0, result[0] # home_win = 100%
    assert_equal 0.0, result[1] # draw = 0%
    assert_equal 0.0, result[2] # home_loss = 0%
  end

  test "handles league with only draws" do
    # Create matches all draws
    10.times do
      @season.matches.create!(
        team_home: @team_home,
        team_away: @team_away,
        status: 'Match Finished',
        result: 'draw',
        home_goals: 1,
        away_goals: 1
      )
    end

    result = LeagueBaselineCalculator.call(league: @league, minimum_matches: 0)

    assert_equal 3, result.length
    assert_equal 0.0, result[0] # home_win = 0%
    assert_equal 1.0, result[1] # draw = 100%
    assert_equal 0.0, result[2] # home_loss = 0%
  end

  test "handles league with only away wins" do
    # Create matches all with away wins (home losses)
    10.times do
      @season.matches.create!(
        team_home: @team_home,
        team_away: @team_away,
        status: 'Match Finished',
        result: 'away',
        home_goals: 0,
        away_goals: 1
      )
    end

    result = LeagueBaselineCalculator.call(league: @league, minimum_matches: 0)

    assert_equal 3, result.length
    assert_equal 0.0, result[0] # home_win = 0%
    assert_equal 0.0, result[1] # draw = 0%
    assert_equal 1.0, result[2] # home_loss = 100%
  end

  test "probabilities sum to 1.0" do # rubocop:disable Metrics/BlockLength
    # Create a mix of results
    30.times do |i|
      result = case i % 3
               when 0 then 'home'
               when 1 then 'draw'
               else 'away'
               end
      @season.matches.create!(
        team_home: @team_home,
        team_away: @team_away,
        status: 'Match Finished',
        result: result,
        home_goals: if result == 'home'
                      1
                    else
                      (result == 'draw' ? 1 : 0)
                    end,
        away_goals: if result == 'away'
                      1
                    else
                      (result == 'draw' ? 1 : 0)
                    end
      )
    end

    result = LeagueBaselineCalculator.call(league: @league, minimum_matches: 0)
    sum = result[0] + result[1] + result[2]

    assert_equal 1.0, sum # Should be exactly 1.0 due to derived third value
  end

  test "only counts finished matches" do
    # Create some finished and some unfinished matches
    @season.matches.create!(
      team_home: @team_home,
      team_away: @team_away,
      status: 'Match Finished',
      result: 'home',
      home_goals: 1,
      away_goals: 0
    )
    @season.matches.create!(
      team_home: @team_home,
      team_away: @team_away,
      status: 'Not Started',
      result: nil,
      home_goals: nil,
      away_goals: nil
    )

    # Use minimum_matches: 0 to test calculation, not default
    result = LeagueBaselineCalculator.call(league: @league, minimum_matches: 0)

    # Should only count the finished match (1 home win)
    assert_equal 3, result.length
    assert_equal 1.0, result[0] # home_win = 100%
    assert_equal 0.0, result[1] # draw = 0%
    assert_equal 0.0, result[2] # home_loss = 0%
  end

  test "returns BigDecimal values for exact precision" do
    # Create matches for testing
    10.times do
      @season.matches.create!(
        team_home: @team_home,
        team_away: @team_away,
        status: 'Match Finished',
        result: 'home',
        home_goals: 1,
        away_goals: 0
      )
    end

    result = LeagueBaselineCalculator.call(league: @league, minimum_matches: 0)

    # All values should be BigDecimal for exact precision
    assert_instance_of BigDecimal, result[0]
    assert_instance_of BigDecimal, result[1]
    assert_instance_of BigDecimal, result[2]
  end
end
