# frozen_string_literal: true

require "test_helper"

class TeamProbabilityInitializerTest < ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
  def setup
    @league = leagues(:a_league)
    @team = teams(:barcelona)
    # League baseline: [0.45, 0.30, 0.25] (home_win, draw, home_loss)
  end

  test "initializes probabilities from league baseline" do
    league_team = TeamProbabilityInitializer.call(league: @league, team: @team)

    assert_not_nil league_team
    assert_equal @league, league_team.league
    assert_equal @team, league_team.team
    # Home probabilities: same as baseline
    assert_equal BigDecimal('0.45'), league_team.home_prob_win
    assert_equal BigDecimal('0.30'), league_team.home_prob_draw
    assert_equal BigDecimal('0.25'), league_team.home_prob_loss
    # Away probabilities: flipped baseline (home_win → away_loss, home_loss → away_win)
    assert_equal BigDecimal('0.25'), league_team.away_prob_win  # home_loss becomes away_win
    assert_equal BigDecimal('0.30'), league_team.away_prob_draw
    assert_equal BigDecimal('0.45'), league_team.away_prob_loss # home_win becomes away_loss
  end

  test "creates LeagueTeam record if doesn't exist" do
    assert_nil LeagueTeam.find_by(league: @league, team: @team)

    league_team = TeamProbabilityInitializer.call(league: @league, team: @team)

    assert_not_nil league_team
    assert league_team.persisted?
    assert_equal @league, league_team.league
    assert_equal @team, league_team.team
  end

  test "does not overwrite existing records" do
    # Create existing record with custom probabilities
    existing = LeagueTeam.create!(
      league: @league,
      team: @team,
      home_prob_win: BigDecimal('0.5'),
      home_prob_draw: BigDecimal('0.3'),
      home_prob_loss: BigDecimal('0.2'),
      away_prob_win: BigDecimal('0.4'),
      away_prob_draw: BigDecimal('0.3'),
      away_prob_loss: BigDecimal('0.3')
    )

    league_team = TeamProbabilityInitializer.call(league: @league, team: @team)

    # Should return existing record without changes
    assert_equal existing.id, league_team.id
    assert_equal BigDecimal('0.5'), league_team.home_prob_win
    assert_equal BigDecimal('0.3'), league_team.home_prob_draw
    assert_equal BigDecimal('0.2'), league_team.home_prob_loss
    assert_equal BigDecimal('0.4'), league_team.away_prob_win
    assert_equal BigDecimal('0.3'), league_team.away_prob_draw
    assert_equal BigDecimal('0.3'), league_team.away_prob_loss
  end

  test "uses league baseline for initialization" do
    league_team = TeamProbabilityInitializer.call(league: @league, team: @team)

    # Verify it uses the league's baseline method
    expected_baseline = @league.baseline

    # Home probabilities: same as baseline
    assert_equal expected_baseline[0], league_team.home_prob_win
    assert_equal expected_baseline[1], league_team.home_prob_draw
    assert_equal expected_baseline[2], league_team.home_prob_loss
    # Away probabilities: flipped (home_win → away_loss, home_loss → away_win)
    assert_equal expected_baseline[2], league_team.away_prob_win
    assert_equal expected_baseline[1], league_team.away_prob_draw
    assert_equal expected_baseline[0], league_team.away_prob_loss
  end

  test "initialized probabilities sum to 1.0 for home" do
    league_team = TeamProbabilityInitializer.call(league: @league, team: @team)

    sum = league_team.home_prob_win + league_team.home_prob_draw + league_team.home_prob_loss
    assert_equal 1.0, sum
  end

  test "initialized probabilities sum to 1.0 for away" do
    league_team = TeamProbabilityInitializer.call(league: @league, team: @team)

    sum = league_team.away_prob_win + league_team.away_prob_draw + league_team.away_prob_loss
    assert_equal 1.0, sum
  end

  test "handles league with custom baseline" do # rubocop:disable Metrics/BlockLength
    # Create a league with calculated baseline (not default)
    custom_league = League.create!(name: "Custom League", reference: 999)
    season = custom_league.seasons.create!(year: 2024)
    team1 = teams(:barcelona)
    team2 = teams(:madrid)

    # Create 500+ matches to get calculated baseline
    # 300 home wins, 150 draws, 150 away wins
    # Use update_columns to avoid triggering callbacks (we're testing initialization, not updates)
    300.times do
      match = season.matches.create!(
        team_home: team1,
        team_away: team2,
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
      match = season.matches.create!(
        team_home: team1,
        team_away: team2,
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
      match = season.matches.create!(
        team_home: team1,
        team_away: team2,
        status: 'Not Started'
      )
      match.update_columns( # rubocop:disable Rails/SkipsModelValidations
        status: 'Match Finished',
        result: 'away',
        home_goals: 0,
        away_goals: 1
      )
    end

    # Verify match count
    finished_count = custom_league.matches.finished.count
    assert_equal 600, finished_count, "Should have 600 finished matches, got #{finished_count}"

    # Verify baseline calculation
    baseline = LeagueBaselineCalculator.call(league: custom_league, minimum_matches: 0)
    assert_equal [0.5.to_d, 0.25.to_d, 0.25.to_d], baseline, "Baseline should be [0.5, 0.25, 0.25], got #{baseline}"

    # Verify league.baseline method returns the same
    league_baseline = custom_league.baseline
    assert_equal [0.5.to_d, 0.25.to_d, 0.25.to_d], league_baseline,
                 "League#baseline should return [0.5, 0.25, 0.25], got #{league_baseline}"

    # Destroy any existing LeagueTeam records to ensure fresh initialization
    LeagueTeam.where(league: custom_league, team: [team1, team2]).destroy_all

    # Baseline should be [0.5, 0.25, 0.25] (300/600, 150/600, 150/600)
    league_team = TeamProbabilityInitializer.call(league: custom_league, team: team1)

    # Home probabilities: [0.5, 0.25, 0.25]
    assert_equal BigDecimal('0.5'), league_team.home_prob_win
    assert_equal BigDecimal('0.25'), league_team.home_prob_draw
    assert_equal BigDecimal('0.25'), league_team.home_prob_loss
    # Away probabilities: flipped [0.25, 0.25, 0.5]
    assert_equal BigDecimal('0.25'), league_team.away_prob_win
    assert_equal BigDecimal('0.25'), league_team.away_prob_draw
    assert_equal BigDecimal('0.5'), league_team.away_prob_loss
  end
end
