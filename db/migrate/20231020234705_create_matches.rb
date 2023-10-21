class CreateMatches < ActiveRecord::Migration[7.1]
  def change
    create_table :matches do |t|
      t.datetime :date
      t.references :team_home, :teams, null: false, foreign_key: true
      t.references :team_away, :teans, null: false, foreign_key: true
      t.string :status
      t.integer :home_goals
      t.integer :away_goals
      t.string :result
      t.integer :reference

      t.timestamps
    end
  end
end
