class CreateSimulationMatchPresets < ActiveRecord::Migration[7.1]
  def change
    create_table :simulation_match_presets do |t|
      t.references :match, null: false, foreign_key: true
      t.references :simulation, null: false, foreign_key: true
      t.string :result

      t.timestamps
    end
  end
end
