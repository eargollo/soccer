# frozen_string_literal: true

class CreateSimulationStandings < ActiveRecord::Migration[7.1]
  def change
    create_table :simulation_standings do |t|
      t.references :simulation, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.float :champion
      t.float :promotion
      t.float :relegation

      t.timestamps
    end
  end
end
