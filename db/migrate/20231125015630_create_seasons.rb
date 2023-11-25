# frozen_string_literal: true

class CreateSeasons < ActiveRecord::Migration[7.1]
  def change
    create_table :seasons do |t|
      t.integer :year
      t.references :league, null: false, foreign_key: true

      t.timestamps
    end
  end
end
