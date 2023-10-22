class CreateStandings < ActiveRecord::Migration[7.1]
  def change
    create_table :standings do |t|
      t.references :team, null: false, foreign_key: true
      t.integer :points
      t.integer :matches
      t.integer :wins
      t.integer :draws
      t.integer :losses
      t.integer :goals_pro
      t.integer :goals_against

      t.timestamps
    end
  end
end
