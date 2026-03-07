# frozen_string_literal: true

class AddIndexStandingsOnSeasonIdAndPosition < ActiveRecord::Migration[8.1]
  def change
    add_index :standings, %i[season_id position], name: "index_standings_on_season_id_and_position"
  end
end
