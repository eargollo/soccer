# frozen_string_literal: true

# == Schema Information
#
# Table name: league_position_counts_matview
#
#  count     :bigint
#  position  :integer
#  league_id :bigint
#  team_id   :bigint
#
# Indexes
#
#  index_league_position_counts_matview_unique  (league_id,team_id,position) UNIQUE
#
require "test_helper"

class LeaguePositionCountTest < ActiveSupport::TestCase
  def setup
    skip "Materialized view not present (run db:migrate)" unless mv_exists?

    @league = leagues(:a_league)
    @team1 = teams(:barcelona)
    @team2 = teams(:madrid)
  end

  test "for_league returns empty array when league has no position data" do
    # Use a league that has no rows in the MV (e.g. no finished seasons with positions)
    other_league = League.create!(name: "Other", reference: 999)
    rows = LeaguePositionCount.for_league(other_league.id, positions: 1..5)
    assert_equal [], rows
    other_league.destroy!
  end

  test "for_league returns rows sorted by most 1st places then 2nd" do
    season = @league.seasons.first
    season.update!(active: false)
    Standing.find_or_initialize_by(season: season, team: @team1).update!(position: 1, points: 10)
    Standing.find_or_initialize_by(season: season, team: @team2).update!(position: 2, points: 9)

    LeaguePositionCount.refresh

    rows = LeaguePositionCount.for_league(@league.id, positions: 1..3)
    assert_equal 2, rows.size
    # First row should be team1 (one 1st place)
    assert_equal @team1.id, rows[0][:team].id
    assert_equal 1, rows[0][:counts][1]
    assert_equal 0, rows[0][:counts][2]
    assert_equal @team2.id, rows[1][:team].id
    assert_equal 0, rows[1][:counts][1]
    assert_equal 1, rows[1][:counts][2]
  end

  test "for_league respects positions range" do
    season = @league.seasons.first
    season.update!(active: false)
    Standing.find_or_initialize_by(season: season, team: @team1).update!(position: 1, points: 10)

    LeaguePositionCount.refresh

    rows = LeaguePositionCount.for_league(@league.id, positions: 1..2)
    assert_equal 1, rows.size
    assert_equal 2, rows[0][:counts].size
    assert rows[0][:counts].key?(1)
    assert rows[0][:counts].key?(2)
  end

  test "refresh runs without error" do
    LeaguePositionCount.refresh
  end

  test "materialized view only includes closed seasons" do
    # Season is still active; standings have position set manually
    season = @league.seasons.first
    season.update!(active: true)
    Standing.find_or_initialize_by(season: season, team: @team1).update!(position: 1, points: 10)
    Standing.find_or_initialize_by(season: season, team: @team2).update!(position: 2, points: 9)

    LeaguePositionCount.refresh

    # MV filters on seasons.active = false, so active season is excluded
    rows = LeaguePositionCount.for_league(@league.id, positions: 1..3)
    assert_equal [], rows, "Position ranking must only count finished (closed) seasons"
  end

  test "after season is closed and MV refreshed, position ranking includes that season" do
    season = @league.seasons.first
    # Ensure standings exist and all matches finished so close can run
    Standing.find_or_initialize_by(season: season, team: @team1).update!(points: 10, wins: 3, draws: 1, losses: 0,
                                                                         matches: 4, goals_pro: 5, goals_against: 2)
    Standing.find_or_initialize_by(season: season, team: @team2).update!(points: 5, wins: 1, draws: 2, losses: 1,
                                                                         matches: 4, goals_pro: 2, goals_against: 5)
    season.matches.update_all(status: "Match Finished") # rubocop:disable Rails/SkipsModelValidations
    season.close
    LeaguePositionCount.refresh

    rows = LeaguePositionCount.for_league(@league.id, positions: 1..5)
    assert rows.size >= 1, "Ranking should have at least one team after closing a season"
    total_first = rows.sum { |r| r[:counts][1] }
    assert total_first >= 1, "At least one team should have finished 1st"
  end

  test "after season is reopened and MV refreshed, position ranking no longer counts that season" do
    season = @league.seasons.first
    Standing.find_or_initialize_by(season: season, team: @team1).update!(points: 10, wins: 3, draws: 1, losses: 0,
                                                                         matches: 4, goals_pro: 5, goals_against: 2)
    Standing.find_or_initialize_by(season: season, team: @team2).update!(points: 5, wins: 1, draws: 2, losses: 1,
                                                                         matches: 4, goals_pro: 2, goals_against: 5)
    season.matches.update_all(status: "Match Finished") # rubocop:disable Rails/SkipsModelValidations
    season.close
    LeaguePositionCount.refresh
    assert LeaguePositionCount.for_league(@league.id, positions: 1..5).size >= 1,
           "Sanity: ranking has data after close"

    season.update!(active: true) # reopen
    LeaguePositionCount.refresh
    rows = LeaguePositionCount.for_league(@league.id, positions: 1..5)
    assert_equal [], rows,
                 "Position ranking must exclude reopened seasons (only active: false counted)"
  end

  private

  def mv_exists?
    ActiveRecord::Base.connection.table_exists?("league_position_counts_matview")
  end
end
