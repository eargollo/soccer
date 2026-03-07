# frozen_string_literal: true

# == Schema Information
#
# Table name: leagues
#
#  id         :bigint           not null, primary key
#  country    :string
#  flag       :string
#  logo       :string
#  name       :string           not null
#  reference  :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "test_helper"

class LeagueTest < ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
  def setup
    @league = leagues(:a_league)
    @season = seasons(:season1)
    @team_home = teams(:barcelona)
    @team_away = teams(:madrid)
  end

  test "baseline returns default probabilities when league has less than 500 matches" do
    result = @league.baseline

    assert_equal 3, result.length
    assert_equal [0.45.to_d, 0.30.to_d, 0.25.to_d], result
  end

  test "baseline returns calculated probabilities when league has 500+ matches" do # rubocop:disable Metrics/BlockLength
    # Create 500 finished matches with known distribution
    # 200 home wins, 150 draws, 150 away wins (home losses)
    # Use update_columns to avoid triggering callbacks (we're testing baseline, not probability updates)
    200.times do
      match = @season.matches.create!(
        team_home: @team_home,
        team_away: @team_away,
        status: 'Not Started'
      )
      match.update_columns( # rubocop:disable Rails/SkipsModelValidations
        status: 'Match Finished',
        result: 'home',
        home_goals: 1,
        away_goals: 0
      )
    end
    150.times do
      match = @season.matches.create!(
        team_home: @team_home,
        team_away: @team_away,
        status: 'Not Started'
      )
      match.update_columns( # rubocop:disable Rails/SkipsModelValidations
        status: 'Match Finished',
        result: 'draw',
        home_goals: 1,
        away_goals: 1
      )
    end
    150.times do
      match = @season.matches.create!(
        team_home: @team_home,
        team_away: @team_away,
        status: 'Not Started'
      )
      match.update_columns( # rubocop:disable Rails/SkipsModelValidations
        status: 'Match Finished',
        result: 'away',
        home_goals: 0,
        away_goals: 1
      )
    end

    result = @league.baseline

    assert_equal 3, result.length
    # 200/500 = 0.4, 150/500 = 0.3, 150/500 = 0.3
    assert_equal BigDecimal('0.4'), result[0] # home_win
    assert_equal BigDecimal('0.3'), result[1] # draw
    assert_equal BigDecimal('0.3'), result[2] # home_loss
  end

  test "baseline returns BigDecimal values" do
    result = @league.baseline

    assert_instance_of BigDecimal, result[0]
    assert_instance_of BigDecimal, result[1]
    assert_instance_of BigDecimal, result[2]
  end

  test "baseline probabilities sum to 1.0" do # rubocop:disable Metrics/BlockLength
    # Create enough matches to trigger calculation
    # Use update_columns to avoid triggering callbacks (we're testing baseline, not probability updates)
    500.times do |i|
      result = case i % 3
               when 0 then 'home'
               when 1 then 'draw'
               else 'away'
               end
      match = @season.matches.create!(
        team_home: @team_home,
        team_away: @team_away,
        status: 'Not Started'
      )
      match.update_columns( # rubocop:disable Rails/SkipsModelValidations
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

    result = @league.baseline
    sum = result[0] + result[1] + result[2]

    assert_equal 1.0, sum
  end

  test "baseline delegates to LeagueBaselineCalculator" do
    # Verify it uses the calculator service
    calculator_result = LeagueBaselineCalculator.call(league: @league)
    model_result = @league.baseline

    assert_equal calculator_result, model_result
  end

  test "has many league_teams" do
    # Create LeagueTeam records
    league_team1 = LeagueTeam.create!(
      league: @league,
      team: @team_home,
      home_prob_win: 0.5.to_d,
      home_prob_draw: 0.3.to_d,
      home_prob_loss: 0.2.to_d,
      away_prob_win: 0.4.to_d,
      away_prob_draw: 0.3.to_d,
      away_prob_loss: 0.3.to_d
    )
    league_team2 = LeagueTeam.create!(
      league: @league,
      team: @team_away,
      home_prob_win: 0.6.to_d,
      home_prob_draw: 0.2.to_d,
      home_prob_loss: 0.2.to_d,
      away_prob_win: 0.3.to_d,
      away_prob_draw: 0.3.to_d,
      away_prob_loss: 0.4.to_d
    )

    assert_includes @league.league_teams, league_team1
    assert_includes @league.league_teams, league_team2
    assert_equal 2, @league.league_teams.count
  end

  test "destroying league destroys associated league_teams" do
    LeagueTeam.create!(
      league: @league,
      home_prob_win: 0.5.to_d,
      team: @team_home,
      home_prob_draw: 0.3.to_d,
      home_prob_loss: 0.2.to_d,
      away_prob_win: 0.4.to_d,
      away_prob_draw: 0.3.to_d,
      away_prob_loss: 0.3.to_d
    )

    league_id = @league.id
    @league.destroy

    assert_nil LeagueTeam.find_by(id: league_id)
  end
end
