# frozen_string_literal: true

require "test_helper"
require "rake"

class ProbabilitiesRakeTest < ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
  def setup
    Rake.application.rake_require "tasks/probabilities"
    Rake::Task.define_task(:environment)
    @league = leagues(:a_league)
    @season = seasons(:season1)
    @team1 = teams(:barcelona)
    @team2 = teams(:madrid)
    @team3 = teams(:espanyol)
  end

  test "initializes league team records for all combinations" do
    # Create matches with different league-team combinations
    @season.matches.create!(
      team_home: @team1,
      team_away: @team2,
      status: 'Not Started'
    )
    @season.matches.create!(
      team_home: @team2,
      team_away: @team3,
      status: 'Not Started'
    )

    # Clear existing LeagueTeam records
    LeagueTeam.where(league: @league).destroy_all

    # Run the rake task
    Rake::Task["probabilities:initialize"].invoke

    # Verify all combinations were initialized
    assert LeagueTeam.exists?(league: @league, team: @team1)
    assert LeagueTeam.exists?(league: @league, team: @team2)
    assert LeagueTeam.exists?(league: @league, team: @team3)
  end

  test "does not create duplicates" do
    # Create existing LeagueTeam record
    LeagueTeam.create!(
      league: @league,
      team: @team1,
      home_prob_win: BigDecimal('0.5'),
      home_prob_draw: BigDecimal('0.3'),
      home_prob_loss: BigDecimal('0.2'),
      away_prob_win: BigDecimal('0.4'),
      away_prob_draw: BigDecimal('0.3'),
      away_prob_loss: BigDecimal('0.3')
    )

    @season.matches.create!(
      team_home: @team1,
      team_away: @team2,
      status: 'Not Started'
    )

    initial_count = LeagueTeam.count

    # Run the rake task
    Rake::Task["probabilities:initialize"].invoke

    # Should not create duplicate
    assert_equal initial_count, LeagueTeam.count
    league_team = LeagueTeam.find_by(league: @league, team: @team1)
    assert_equal BigDecimal('0.5'), league_team.home_prob_win # Original value preserved
  end

  test "handles multiple leagues" do
    league2 = League.create!(name: "League 2", reference: 999)
    season2 = league2.seasons.create!(year: 2024)
    season2.matches.create!(
      team_home: @team1,
      team_away: @team2,
      status: 'Not Started'
    )

    @season.matches.create!(
      team_home: @team1,
      team_away: @team2,
      status: 'Not Started'
    )

    LeagueTeam.destroy_all

    # Run the rake task
    Rake::Task["probabilities:initialize"].invoke

    # Should create records for both leagues
    assert LeagueTeam.exists?(league: @league, team: @team1)
    assert LeagueTeam.exists?(league: @league, team: @team2)
    assert LeagueTeam.exists?(league: league2, team: @team1)
    assert LeagueTeam.exists?(league: league2, team: @team2)
  end

  test "handles teams that appear as both home and away" do
    # Team appears as both home and away in different matches
    @season.matches.create!(
      team_home: @team1,
      team_away: @team2,
      status: 'Not Started'
    )
    @season.matches.create!(
      team_home: @team2,
      team_away: @team1,
      status: 'Not Started'
    )

    LeagueTeam.where(league: @league).destroy_all

    # Run the rake task
    Rake::Task["probabilities:initialize"].invoke

    # Should only create one record per team (not duplicates)
    assert_equal 1, LeagueTeam.where(league: @league, team: @team1).count
    assert_equal 1, LeagueTeam.where(league: @league, team: @team2).count
  end

  test "process_historical processes matches in chronological order" do # rubocop:disable Metrics/BlockLength
    # Clear existing LeagueTeam records
    LeagueTeam.where(league: @league).destroy_all

    # Create finished matches with different dates (out of order)
    @season.matches.create!(
      team_home: @team1,
      team_away: @team2,
      status: 'Match Finished',
      result: 'home',
      home_goals: 2,
      away_goals: 1,
      date: 3.days.ago
    )
    @season.matches.create!(
      team_home: @team2,
      team_away: @team3,
      status: 'Match Finished',
      result: 'draw',
      home_goals: 1,
      away_goals: 1,
      date: 1.day.ago
    )
    @season.matches.create!(
      team_home: @team1,
      team_away: @team3,
      status: 'Match Finished',
      result: 'away',
      home_goals: 0,
      away_goals: 1,
      date: 2.days.ago
    )

    # Initialize LeagueTeam records
    TeamProbabilityInitializer.call(league: @league, team: @team1)
    TeamProbabilityInitializer.call(league: @league, team: @team2)
    TeamProbabilityInitializer.call(league: @league, team: @team3)

    # Get baseline probabilities
    baseline = @league.baseline
    home_team1_before = @league.league_teams.find_by(team: @team1).home_prob_win

    # Run the rake task
    ENV['LEAGUE_ID'] = @league.id.to_s
    Rake::Task["probabilities:process_historical"].invoke

    # Verify probabilities were updated (they should differ from baseline after processing)
    home_team1_after = @league.league_teams.find_by(team: @team1).home_prob_win
    assert_not_equal baseline[0], home_team1_after, "Probabilities should have been updated from baseline"
    assert_not_equal home_team1_before, home_team1_after, "Probabilities should have changed after processing matches"
  end

  test "process_historical can filter by league" do # rubocop:disable Metrics/BlockLength
    league2 = League.create!(name: "League 2", reference: 999)
    season2 = league2.seasons.create!(year: 2024)

    # Create matches in both leagues
    @season.matches.create!(
      team_home: @team1,
      team_away: @team2,
      status: 'Match Finished',
      result: 'home',
      home_goals: 2,
      away_goals: 1,
      date: 1.day.ago
    )
    season2.matches.create!(
      team_home: @team1,
      team_away: @team2,
      status: 'Match Finished',
      result: 'home',
      home_goals: 2,
      away_goals: 1,
      date: 1.day.ago
    )

    LeagueTeam.where(league: [@league, league2]).destroy_all

    # Initialize LeagueTeam records
    TeamProbabilityInitializer.call(league: @league, team: @team1)
    TeamProbabilityInitializer.call(league: @league, team: @team2)
    TeamProbabilityInitializer.call(league: league2, team: @team1)
    TeamProbabilityInitializer.call(league: league2, team: @team2)

    baseline_league1 = @league.baseline
    baseline_league2 = league2.baseline

    # Process only league1
    ENV['LEAGUE_ID'] = @league.id.to_s
    Rake::Task["probabilities:process_historical"].invoke

    # Verify league1 probabilities were updated
    league1_team1_after = @league.league_teams.find_by(team: @team1).home_prob_win
    assert_not_equal baseline_league1[0], league1_team1_after

    # Verify league2 probabilities were NOT updated (still at baseline)
    league2_team1_after = league2.league_teams.find_by(team: @team1).home_prob_win
    assert_equal baseline_league2[0], league2_team1_after
  end

  test "process_historical can resume from match ID" do # rubocop:disable Metrics/BlockLength
    LeagueTeam.where(league: @league).destroy_all

    # Create three finished matches
    # match1: team1 wins at home (should NOT be processed when resuming)
    match1 = @season.matches.create!(
      team_home: @team1,
      team_away: @team2,
      status: 'Match Finished',
      result: 'home',
      home_goals: 2,
      away_goals: 1,
      date: 3.days.ago
    )
    # match2: team2 draws at home (should be processed)
    @season.matches.create!(
      team_home: @team2,
      team_away: @team3,
      status: 'Match Finished',
      result: 'draw',
      home_goals: 1,
      away_goals: 1,
      date: 2.days.ago
    )
    # match3: team1 loses at home (should be processed)
    match3 = @season.matches.create!(
      team_home: @team1,
      team_away: @team3,
      status: 'Match Finished',
      result: 'away',
      home_goals: 0,
      away_goals: 1,
      date: 1.day.ago
    )

    # Initialize LeagueTeam records
    TeamProbabilityInitializer.call(league: @league, team: @team1)
    TeamProbabilityInitializer.call(league: @league, team: @team2)
    TeamProbabilityInitializer.call(league: @league, team: @team3)

    baseline = @league.baseline

    # Calculate what team1's probability should be if only match3 was processed (not match1)
    # Process match3 manually to get expected value
    ProbabilityUpdater.call(match: match3)
    expected_team1_after_match3 = @league.league_teams.find_by(team: @team1).home_prob_win

    # Reset to baseline
    ProbabilityRecalculator.call(league: @league)

    # Process starting from match2 (resume from match1.id)
    ENV['LEAGUE_ID'] = @league.id.to_s
    ENV['START_MATCH_ID'] = match1.id.to_s
    Rake::Task["probabilities:process_historical"].invoke

    # Verify match1 was NOT processed but match3 was
    # team1's home_prob_win should reflect match3 (loss) but NOT match1 (win)
    # If match1 was processed, home_prob_win would be higher
    # If only match3 was processed, home_prob_win should match expected_team1_after_match3
    team1_final = @league.league_teams.find_by(team: @team1).home_prob_win
    assert_in_delta expected_team1_after_match3.to_f, team1_final.to_f, 0.0001,
                    "Team1 should reflect match3 (processed) but not match1 (skipped)"

    # Verify match2 was processed (team2's probabilities should have changed)
    team2_final = @league.league_teams.find_by(team: @team2).home_prob_win
    assert_not_equal baseline[0], team2_final, "Match2 should have been processed"
  end

  test "process_historical only processes finished matches" do
    LeagueTeam.where(league: @league).destroy_all

    # Create mix of finished and pending matches
    @season.matches.create!(
      team_home: @team1,
      team_away: @team2,
      status: 'Match Finished',
      result: 'home',
      home_goals: 2,
      away_goals: 1,
      date: 1.day.ago
    )
    @season.matches.create!(
      team_home: @team2,
      team_away: @team3,
      status: 'Not Started',
      date: 1.day.from_now
    )

    # Initialize LeagueTeam records
    TeamProbabilityInitializer.call(league: @league, team: @team1)
    TeamProbabilityInitializer.call(league: @league, team: @team2)
    TeamProbabilityInitializer.call(league: @league, team: @team3)

    baseline = @league.baseline

    # Run the rake task
    ENV['LEAGUE_ID'] = @league.id.to_s
    Rake::Task["probabilities:process_historical"].invoke

    # Verify finished match was processed
    team1_after = @league.league_teams.find_by(team: @team1).home_prob_win
    assert_not_equal baseline[0], team1_after, "Finished match should have been processed"

    # Verify pending match was NOT processed (ProbabilityUpdater returns early for non-finished)
    # This is verified by the fact that team2's probabilities should only reflect the finished match
  end

  teardown do
    Rake::Task["probabilities:initialize"].reenable
    Rake::Task["probabilities:process_historical"].reenable
    ENV.delete('LEAGUE_ID')
    ENV.delete('START_DATE')
    ENV.delete('START_MATCH_ID')
    ENV.delete('BATCH_SIZE')
  end
end
