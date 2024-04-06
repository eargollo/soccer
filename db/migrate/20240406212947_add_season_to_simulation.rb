# frozen_string_literal: true

class AddSeasonToSimulation < ActiveRecord::Migration[7.1]
  def change
    add_reference :simulations, :season, null: false, default: 1, foreign_key: true
  end
end
