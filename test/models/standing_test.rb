require "test_helper"

class StandingTest < ActiveSupport::TestCase
  def setup
    @bcn = teams(:barcelona)
    @rmd = teams(:madrid)
  end

  test "calculate wins, draws, losses and points" do
    Match.create(team_home: @bcn, team_away: @rmd, home_goals: 2, away_goals: 1, status: 'finished')
    Match.create(team_home: @bcn, team_away: @rmd, home_goals: 4, away_goals: 2, status: 'finished')
    Match.create(team_home: @bcn, team_away: @rmd, home_goals: 3, away_goals: 3, status: 'finished')
    Match.create(team_home: @rmd, team_away: @bcn, home_goals: 3, away_goals: 0, status: 'finished')
    Match.create(team_home: @rmd, team_away: @bcn, home_goals: 0, away_goals: 0, status: 'finished')
    Match.create(team_home: @rmd, team_away: @bcn, home_goals: 0, away_goals: 1, status: 'finished')
    Match.create(team_home: @rmd, team_away: @bcn, home_goals: 8, away_goals: 8, status: 'pending')

    # Standing.compute(@bcn)
    stdBcn = Standing.find_by(team: @bcn)
    assert_equal 10, stdBcn.goals_pro
    assert_equal 9, stdBcn.goals_against
    assert_equal 3, stdBcn.wins
    assert_equal 2, stdBcn.draws
    assert_equal 1, stdBcn.losses
    assert_equal 11, stdBcn.points
    assert_equal 6, stdBcn.matches


    stdMad = Standing.find_by(team: @rmd)
    assert_equal 9, stdMad.goals_pro
    assert_equal 10, stdMad.goals_against
    assert_equal 1, stdMad.wins
    assert_equal 2, stdMad.draws
    assert_equal 3, stdMad.losses
    assert_equal 5, stdMad.points
    assert_equal 6, stdMad.matches
  end
end
