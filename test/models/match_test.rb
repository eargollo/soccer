# frozen_string_literal: true

require "test_helper"

class MatchTest < ActiveSupport::TestCase
  # BASE * 1 + LEAGUE * 19 + TEAM_LAST_SEASON  * 20 + LAST_30 * 60
  FACTOR = 4.5
  def setup
    @bcn = teams(:barcelona)
    @mad = teams(:madrid)
    @esp = teams(:espanyol)

    @prev_season = leagues(:a_league).seasons.create(year: 2022)
    @season = seasons(:season1)
  end

  test "standard probability with no matches" do
    assert_equal([0.45, 0.30, 0.25], @season.matches.new.probability.map { |f| f.round(2) })
  end

  test "standard and league probabilities when new teams" do
  end

  def round_array(array)
    array.map { |f| f.round(2) }
  end
  test "balanced probability with match" do
    @season.matches.create(team_home: @bcn, team_away: @esp, home_goals: 0, away_goals: 1, status: 'finished')
    m = @season.matches.create(team_home: @bcn, team_away: @mad, home_goals: 0, away_goals: 0, status: 'pending')
    exp_win = (0.45 + (FACTOR * 0) + (FACTOR * 0.25)) / 10
    exp_draw = (0.30 + (FACTOR * 0) + (FACTOR * 0.30)) / 10
    exp_loss = (0.25 + (FACTOR * 1) + (FACTOR * 0.45)) / 10
    assert_equal(round_array([exp_win, exp_draw, exp_loss]), round_array(m.probability))
  end

  test "balanced probability with milti matches" do
    @season.matches.create(team_home: @bcn, team_away: @esp, home_goals: 0, away_goals: 1, status: 'finished')
    @season.matches.create(team_home: @bcn, team_away: @esp, home_goals: 0, away_goals: 0, status: 'finished')
    @season.matches.create(team_home: @esp, team_away: @mad, home_goals: 0, away_goals: 1, status: 'finished')
    m = @season.matches.create(team_home: @bcn, team_away: @mad, home_goals: 0, away_goals: 0, status: 'pending')
    exp_win = (0.45 + 0 + 0) / 10
    exp_draw = (0.30 + (FACTOR * 0.5) + 0) / 10
    exp_loss = (0.25 + (FACTOR * 0.5) + (FACTOR * 1)) / 10
    assert_equal(round_array([exp_win, exp_draw, exp_loss]), round_array(m.probability))
  end
end
