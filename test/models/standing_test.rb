# frozen_string_literal: true

require "test_helper"

class StandingTest < ActiveSupport::TestCase
  def setup
    @season = seasons(:season_23)

    @bcn = teams(:barcelona)
    @rmd = teams(:madrid)
  end

  test "calculate wins, draws, losses and points" do
    @season.matches.create(team_home: @bcn, team_away: @rmd, home_goals: 2, away_goals: 1, status: 'finished')
    @season.matches.create(team_home: @bcn, team_away: @rmd, home_goals: 4, away_goals: 2, status: 'finished')
    @season.matches.create(team_home: @bcn, team_away: @rmd, home_goals: 3, away_goals: 3, status: 'finished')
    @season.matches.create(team_home: @rmd, team_away: @bcn, home_goals: 3, away_goals: 0, status: 'finished')
    @season.matches.create(team_home: @rmd, team_away: @bcn, home_goals: 0, away_goals: 0, status: 'finished')
    @season.matches.create(team_home: @rmd, team_away: @bcn, home_goals: 0, away_goals: 1, status: 'finished')
    @season.matches.create(team_home: @rmd, team_away: @bcn, home_goals: 8, away_goals: 8, status: 'pending')

    # Standing.compute(@bcn)
    std_bcn = Standing.find_by(team: @bcn)
    assert_equal 10, std_bcn.goals_pro
    assert_equal 9, std_bcn.goals_against
    assert_equal 3, std_bcn.wins
    assert_equal 2, std_bcn.draws
    assert_equal 1, std_bcn.losses
    assert_equal 11, std_bcn.points
    assert_equal 6, std_bcn.matches

    std_mad = Standing.find_by(team: @rmd)
    assert_equal 9, std_mad.goals_pro
    assert_equal 10, std_mad.goals_against
    assert_equal 1, std_mad.wins
    assert_equal 2, std_mad.draws
    assert_equal 3, std_mad.losses
    assert_equal 5, std_mad.points
    assert_equal 6, std_mad.matches
  end
end
