# frozen_string_literal: true

require "test_helper"

class MatchTest < ActiveSupport::TestCase
  FACTOR = 4.5
  def setup
    @bcn = teams(:barcelona)
    @mad = teams(:madrid)
    @esp = teams(:espanyol)
  end
  test "standard probability with no matches" do
    assert_equal([0.45, 0.30, 0.25], Match.new.probability.map { |f| f.round(2) })
  end

  def round_array(array)
    array.map { |f| f.round(2) }
  end
  test "balanced probability with match" do
    Match.create(team_home: @bcn, team_away: @esp, home_goals: 0, away_goals: 1, status: 'finished')
    m = Match.create(team_home: @bcn, team_away: @mad, home_goals: 0, away_goals: 0, status: 'pending')
    exp_win = (0.45 + (FACTOR * 0) + (FACTOR * 0.25)) / 10
    exp_draw = (0.30 + (FACTOR * 0) + (FACTOR * 0.30)) / 10
    exp_loss = (0.25 + (FACTOR * 1) + (FACTOR * 0.45)) / 10
    assert_equal(round_array([exp_win, exp_draw, exp_loss]), round_array(m.probability))
  end

  test "balanced probability with milti matches" do
    Match.create(team_home: @bcn, team_away: @esp, home_goals: 0, away_goals: 1, status: 'finished')
    Match.create(team_home: @bcn, team_away: @esp, home_goals: 0, away_goals: 0, status: 'finished')
    Match.create(team_home: @esp, team_away: @mad, home_goals: 0, away_goals: 1, status: 'finished')
    m = Match.create(team_home: @bcn, team_away: @mad, home_goals: 0, away_goals: 0, status: 'pending')
    exp_win = (0.45 + 0 + 0) / 10
    exp_draw = (0.30 + (FACTOR * 0.5) + 0) / 10
    exp_loss = (0.25 + (FACTOR * 0.5) + (FACTOR * 1)) / 10
    assert_equal(round_array([exp_win, exp_draw, exp_loss]), round_array(m.probability))
  end
end
