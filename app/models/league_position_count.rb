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
class LeaguePositionCount < ApplicationRecord
  self.table_name = "league_position_counts_matview"

  belongs_to :league
  belongs_to :team

  # Returns medals-board rows for a league: array of { team:, counts: } sorted by
  # most 1st places, then 2nd, etc. Counts is a hash position => count (0 for missing).
  def self.for_league(league_id, positions: 1..10) # rubocop:disable Metrics/AbcSize
    positions = positions.to_a
    records = where(league_id: league_id, position: positions).includes(:team)
    grouped = records.group_by(&:team_id)

    rows = grouped.map do |_team_id, recs|
      count_by_pos = positions.index_with { 0 }
      recs.each { |r| count_by_pos[r.position] = r.count }
      team = recs.first.team
      { team: team, counts: count_by_pos }
    end

    rows.sort_by! do |row|
      positions.map { |p| -row[:counts][p] }
    end

    rows
  end

  def self.refresh
    ActiveRecord::Base.connection.execute("REFRESH MATERIALIZED VIEW league_position_counts_matview;")
  end
end
