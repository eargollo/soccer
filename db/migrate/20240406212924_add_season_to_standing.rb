# frozen_string_literal: true

class AddSeasonToStanding < ActiveRecord::Migration[7.1]
  def change
    add_reference :standings, :season, null: false, default: 1, foreign_key: true
  end
end
