# frozen_string_literal: true

class CreateSimulationStandingPositions < ActiveRecord::Migration[7.1]
  def change
    create_table :simulation_standing_positions do |t|
      t.references :simulation, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.integer :position
      t.integer :count

      t.timestamps
    end
  end
end
