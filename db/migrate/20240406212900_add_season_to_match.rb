# frozen_string_literal: true

class AddSeasonToMatch < ActiveRecord::Migration[7.1]
  def change
    add_reference :matches, :season, null: false, default: 1, foreign_key: true
  end
end
