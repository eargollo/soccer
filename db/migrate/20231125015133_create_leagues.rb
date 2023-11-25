# frozen_string_literal: true

class CreateLeagues < ActiveRecord::Migration[7.1]
  def change
    create_table :leagues do |t|
      t.string :name
      t.string :logo
      t.string :model
      t.integer :reference

      t.timestamps
    end
  end
end
