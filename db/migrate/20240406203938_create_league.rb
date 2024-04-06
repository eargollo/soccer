# frozen_string_literal: true

class CreateLeague < ActiveRecord::Migration[7.1]
  def change
    create_table :leagues do |t|
      t.string :name, null: false
      t.integer :reference, null: false
      t.string :country
      t.string :logo
      t.string :flag

      t.timestamps
    end
  end
end
