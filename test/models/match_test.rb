# frozen_string_literal: true

# == Schema Information
#
# Table name: matches
#
#  id           :bigint           not null, primary key
#  away_goals   :integer
#  date         :datetime
#  home_goals   :integer
#  reference    :integer
#  result       :string
#  round        :integer
#  round_name   :string
#  status       :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  season_id    :bigint           default(1), not null
#  team_away_id :bigint           not null
#  team_home_id :bigint           not null
#
# Indexes
#
#  index_matches_on_season_id     (season_id)
#  index_matches_on_team_away_id  (team_away_id)
#  index_matches_on_team_home_id  (team_home_id)
#
# Foreign Keys
#
#  fk_rails_...  (season_id => seasons.id)
#  fk_rails_...  (team_away_id => teams.id)
#  fk_rails_...  (team_home_id => teams.id)
#
require "test_helper"

class MatchTest < ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
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

  test "probability_legacy returns same result as probability" do
    match = @season.matches.new(team_home: @bcn, team_away: @mad)
    probability_result = match.probability
    legacy_result = match.probability_legacy

    assert_equal(probability_result, legacy_result, "probability and probability_legacy should return the same result")
  end

  test "probability_legacy returns default probabilities when teams are nil" do
    match = @season.matches.new
    result = match.probability_legacy

    assert_equal([Match::PROB_WIN, Match::PROB_DRAW, Match::PROB_LOSS], result)
  end

  test "probability uses legacy calculation when feature flag is false" do
    original_flag = Rails.application.config.probability.use_ema_calculation
    Rails.application.config.probability.use_ema_calculation = false

    match = @season.matches.new(team_home: @bcn, team_away: @mad)
    probability_result = match.probability
    legacy_result = match.probability_legacy

    assert_equal(legacy_result, probability_result, "probability should use legacy when flag is false")
  ensure
    Rails.application.config.probability.use_ema_calculation = original_flag
  end

  test "probability uses EMA calculation when feature flag is true" do
    original_flag = Rails.application.config.probability.use_ema_calculation
    Rails.application.config.probability.use_ema_calculation = true

    # Ensure LeagueTeam records exist for the test
    LeagueTeam.where(league: @season.league, team: [@bcn, @mad]).destroy_all
    TeamProbabilityInitializer.call(league: @season.league, team: @bcn)
    TeamProbabilityInitializer.call(league: @season.league, team: @mad)

    match = @season.matches.new(team_home: @bcn, team_away: @mad)
    probability_result = match.probability
    ema_result = match.probability_ema

    assert_equal(ema_result, probability_result, "probability should use EMA when flag is true")
  ensure
    Rails.application.config.probability.use_ema_calculation = original_flag
  end

  test "probability_ema returns default probabilities when teams are nil" do
    match = @season.matches.new
    result = match.probability_ema

    assert_equal([Match::PROB_WIN, Match::PROB_DRAW, Match::PROB_LOSS], result)
  end

  test "probability_ema returns default probabilities when league is nil" do
    # Create a match without a season (which means no league)
    match = Match.new(team_home: @bcn, team_away: @mad)
    result = match.probability_ema

    assert_equal([Match::PROB_WIN, Match::PROB_DRAW, Match::PROB_LOSS], result)
  end

  test "EMA calculation integration with helper methods" do
    original_flag = Rails.application.config.probability.use_ema_calculation
    Rails.application.config.probability.use_ema_calculation = true

    # Ensure LeagueTeam records exist with initialized probabilities
    LeagueTeam.where(league: @season.league, team: [@bcn, @mad]).destroy_all
    TeamProbabilityInitializer.call(league: @season.league, team: @bcn)
    TeamProbabilityInitializer.call(league: @season.league, team: @mad)

    match = @season.matches.new(team_home: @bcn, team_away: @mad)

    # Test that probability returns EMA result
    probability_result = match.probability
    ema_result = match.probability_ema
    assert_equal(ema_result, probability_result, "probability should return EMA result when flag is true")

    # Test that probabilities are valid (sum to 1, all between 0 and 1)
    assert_in_delta(1.0, probability_result.sum, 0.0001, "probabilities should sum to 1.0")
    probability_result.each do |prob|
      assert prob >= 0, "probability should be >= 0"
      assert prob <= 1, "probability should be <= 1"
    end

    # Test that helper methods work correctly
    assert_equal(probability_result[0], match.prob_win, "prob_win should return first element")
    assert_equal(probability_result[1], match.prob_draw, "prob_draw should return second element")
    assert_equal(probability_result[2], match.prob_loss, "prob_loss should return third element")

    # Test prob_not_loss helper
    expected_not_loss = probability_result[0] + probability_result[1]
    assert_in_delta(expected_not_loss, match.prob_not_loss, 0.0001, "prob_not_loss should be win + draw")
  ensure
    Rails.application.config.probability.use_ema_calculation = original_flag
  end

  test "EMA calculation uses MatchProbabilityCalculator" do
    original_flag = Rails.application.config.probability.use_ema_calculation
    Rails.application.config.probability.use_ema_calculation = true

    LeagueTeam.where(league: @season.league, team: [@bcn, @mad]).destroy_all
    TeamProbabilityInitializer.call(league: @season.league, team: @bcn)
    TeamProbabilityInitializer.call(league: @season.league, team: @mad)

    match = @season.matches.new(team_home: @bcn, team_away: @mad)

    # Verify that MatchProbabilityCalculator is called
    calculator_result = MatchProbabilityCalculator.call(match: match)
    ema_result = match.probability_ema

    assert_equal(calculator_result, ema_result, "probability_ema should use MatchProbabilityCalculator")
  ensure
    Rails.application.config.probability.use_ema_calculation = original_flag
  end

  test "initializes league team probabilities when match is created" do
    # Ensure no existing LeagueTeam records
    LeagueTeam.where(league: @season.league, team: [@bcn, @mad]).destroy_all

    @season.matches.create!(
      team_home: @bcn,
      team_away: @mad,
      status: 'Not Started'
    )

    # Verify LeagueTeam records were created for both teams
    home_league_team = LeagueTeam.find_by(league: @season.league, team: @bcn)
    away_league_team = LeagueTeam.find_by(league: @season.league, team: @mad)

    assert_not_nil home_league_team
    assert_not_nil away_league_team
    assert home_league_team.persisted?
    assert away_league_team.persisted?
  end

  test "initializes probabilities from league baseline" do
    LeagueTeam.where(league: @season.league, team: [@bcn, @mad]).destroy_all

    @season.matches.create!(
      team_home: @bcn,
      team_away: @mad,
      status: 'Not Started'
    )

    baseline = @season.league.baseline
    home_league_team = LeagueTeam.find_by(league: @season.league, team: @bcn)
    away_league_team = LeagueTeam.find_by(league: @season.league, team: @mad)

    # Home team: probabilities same as baseline
    assert_equal baseline[0], home_league_team.home_prob_win
    assert_equal baseline[1], home_league_team.home_prob_draw
    assert_equal baseline[2], home_league_team.home_prob_loss

    # Away team: probabilities flipped
    assert_equal baseline[2], away_league_team.away_prob_win
    assert_equal baseline[1], away_league_team.away_prob_draw
    assert_equal baseline[0], away_league_team.away_prob_loss
  end

  test "does not overwrite existing league team probabilities" do
    # Create existing LeagueTeam with custom probabilities
    existing_home = LeagueTeam.create!(
      league: @season.league,
      team: @bcn,
      home_prob_win: BigDecimal('0.6'),
      home_prob_draw: BigDecimal('0.2'),
      home_prob_loss: BigDecimal('0.2'),
      away_prob_win: BigDecimal('0.3'),
      away_prob_draw: BigDecimal('0.3'),
      away_prob_loss: BigDecimal('0.4')
    )

    @season.matches.create!(
      team_home: @bcn,
      team_away: @mad,
      status: 'Not Started'
    )

    # Verify existing record was not changed
    existing_home.reload
    assert_equal BigDecimal('0.6'), existing_home.home_prob_win
    assert_equal BigDecimal('0.2'), existing_home.home_prob_draw
    assert_equal BigDecimal('0.2'), existing_home.home_prob_loss
  end

  test "initializes probabilities for both teams in match" do
    LeagueTeam.where(league: @season.league, team: [@bcn, @mad, @esp]).destroy_all

    @season.matches.create!(
      team_home: @bcn,
      team_away: @mad,
      status: 'Not Started'
    )

    # Both teams should have LeagueTeam records
    assert LeagueTeam.exists?(league: @season.league, team: @bcn)
    assert LeagueTeam.exists?(league: @season.league, team: @mad)
    # Third team should not have a record yet
    assert_not LeagueTeam.exists?(league: @season.league, team: @esp)
  end

  def round_array(array)
    array.map { |f| f.round(2) }
  end

  test "updates probabilities when match is created as finished" do # rubocop:disable Metrics/BlockLength
    LeagueTeam.where(league: @season.league, team: [@bcn, @mad]).destroy_all

    # Initialize LeagueTeam records first
    TeamProbabilityInitializer.call(league: @season.league, team: @bcn)
    TeamProbabilityInitializer.call(league: @season.league, team: @mad)

    home_league_team = LeagueTeam.find_by(league: @season.league, team: @bcn)
    away_league_team = LeagueTeam.find_by(league: @season.league, team: @mad)

    original_home_win = home_league_team.home_prob_win
    original_home_draw = home_league_team.home_prob_draw
    original_home_loss = home_league_team.home_prob_loss
    original_away_win = away_league_team.away_prob_win
    original_away_draw = away_league_team.away_prob_draw
    original_away_loss = away_league_team.away_prob_loss

    # Create match as finished from the start
    @season.matches.create!(
      team_home: @bcn,
      team_away: @mad,
      status: 'Match Finished',
      result: 'home',
      home_goals: 2,
      away_goals: 1
    )

    # Wait for after_commit callback
    home_league_team.reload
    away_league_team.reload

    # Probabilities should have been updated
    assert home_league_team.home_prob_win > original_home_win
    assert home_league_team.home_prob_draw < original_home_draw
    assert home_league_team.home_prob_loss < original_home_loss
    assert away_league_team.away_prob_loss > original_away_loss
    assert away_league_team.away_prob_draw < original_away_draw
    assert away_league_team.away_prob_win < original_away_win
  end

  test "updates probabilities when match status changes to finished" do # rubocop:disable Metrics/BlockLength
    LeagueTeam.where(league: @season.league, team: [@bcn, @mad]).destroy_all

    # Initialize LeagueTeam records first
    TeamProbabilityInitializer.call(league: @season.league, team: @bcn)
    TeamProbabilityInitializer.call(league: @season.league, team: @mad)

    home_league_team = LeagueTeam.find_by(league: @season.league, team: @bcn)
    away_league_team = LeagueTeam.find_by(league: @season.league, team: @mad)

    original_home_win = home_league_team.home_prob_win
    original_away_loss = away_league_team.away_prob_loss

    # Create match as not started
    match = @season.matches.create!(
      team_home: @bcn,
      team_away: @mad,
      status: 'Not Started'
    )

    # Probabilities should not have changed yet
    home_league_team.reload
    away_league_team.reload
    assert_equal original_home_win, home_league_team.home_prob_win
    assert_equal original_away_loss, away_league_team.away_prob_loss

    # Update match to finished
    match.update!(
      status: 'Match Finished',
      result: 'home',
      home_goals: 2,
      away_goals: 1
    )

    # Wait for after_commit callback
    home_league_team.reload
    away_league_team.reload

    # Probabilities should have been updated
    assert home_league_team.home_prob_win > original_home_win
    assert away_league_team.away_prob_loss > original_away_loss
  end

  test "does not update probabilities if match is not finished" do
    LeagueTeam.where(league: @season.league, team: [@bcn, @mad]).destroy_all

    TeamProbabilityInitializer.call(league: @season.league, team: @bcn)
    TeamProbabilityInitializer.call(league: @season.league, team: @mad)

    home_league_team = LeagueTeam.find_by(league: @season.league, team: @bcn)
    original_home_win = home_league_team.home_prob_win

    # Create match as not started
    match = @season.matches.create!(
      team_home: @bcn,
      team_away: @mad,
      status: 'Not Started'
    )

    # Update match but keep it not finished
    match.update!(
      home_goals: 2,
      away_goals: 1
    )

    home_league_team.reload
    assert_equal original_home_win, home_league_team.home_prob_win
  end

  test "validates that finished matches must have goals" do
    # Match cannot be finished without goals
    match = @season.matches.build(
      team_home: @bcn,
      team_away: @mad,
      status: 'Match Finished'
    )

    assert_not match.valid?
    assert_includes match.errors[:home_goals], "can't be blank"
    assert_includes match.errors[:away_goals], "can't be blank"
  end
end
