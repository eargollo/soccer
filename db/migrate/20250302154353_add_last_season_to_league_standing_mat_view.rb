# frozen_string_literal: true

class AddLastSeasonToLeagueStandingMatView < ActiveRecord::Migration[7.2]
  def up
    execute <<-SQL.squish

      DROP MATERIALIZED VIEW league_standings_matview;

      CREATE MATERIALIZED VIEW league_standings_matview AS
        SELECT  teams.id as team_id,
                seasons.league_id as league_id,
                sum(standings.points) as points,
                sum(standings.matches) as matches,
                sum(standings.wins) as wins,
                sum(standings.draws) as draws,
                sum(standings.losses) as losses,
                sum(standings.goals_pro) as goals_pro,
                sum(standings.goals_against) as goals_against,
                count(seasons.id) as seasons,
                max(seasons.year) as last_season
          FROM teams, standings, seasons
          WHERE teams.id = standings.team_id AND standings.season_id = seasons.id
          GROUP BY teams.id, seasons.league_id;
    SQL
  end

  def down
    execute <<-SQL.squish
      DROP MATERIALIZED VIEW league_standings_matview;
      CREATE MATERIALIZED VIEW league_standings_matview AS
        SELECT  teams.id as team_id,
                seasons.league_id as league_id,
                sum(standings.points) as points,
                sum(standings.matches) as matches,
                sum(standings.wins) as wins,
                sum(standings.draws) as draws,
                sum(standings.losses) as losses,
                sum(standings.goals_pro) as goals_pro,
                sum(standings.goals_against) as goals_against,
                count(seasons.id) as seasons
          FROM teams, standings, seasons
          WHERE teams.id = standings.team_id AND standings.season_id = seasons.id
          GROUP BY teams.id, seasons.league_id;
    SQL
  end
end
