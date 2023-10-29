class CreateSimulations < ActiveRecord::Migration[7.1]
  def change
    create_table :simulations do |t|
      t.string :name
      t.integer :runs
      t.datetime :start
      t.datetime :finish

      t.timestamps
    end
  end
end
