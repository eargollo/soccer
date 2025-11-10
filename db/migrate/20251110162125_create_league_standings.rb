class CreateLeagueStandings < ActiveRecord::Migration[8.0]
  def change
    create_view :league_standings
  end
end
