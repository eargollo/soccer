# frozen_string_literal: true

class AddSeasonRefToMatches < ActiveRecord::Migration[7.1]
  def change
    add_reference :matches, :season, null: true, foreign_key: true
  end
end
