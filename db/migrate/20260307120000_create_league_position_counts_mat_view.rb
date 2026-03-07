# frozen_string_literal: true

class CreateLeaguePositionCountsMatView < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      CREATE MATERIALIZED VIEW league_position_counts_matview AS
        SELECT
          seasons.league_id AS league_id,
          standings.team_id AS team_id,
          standings.position AS position,
          count(*) AS count
        FROM standings
        INNER JOIN seasons ON seasons.id = standings.season_id
        WHERE seasons.active = false
          AND standings.position BETWEEN 1 AND 20
        GROUP BY seasons.league_id, standings.team_id, standings.position
    SQL

    execute <<~SQL.squish
      CREATE UNIQUE INDEX index_league_position_counts_matview_unique
        ON league_position_counts_matview (league_id, team_id, position)
    SQL
  end

  def down
    execute "DROP MATERIALIZED VIEW IF EXISTS league_position_counts_matview"
  end
end
