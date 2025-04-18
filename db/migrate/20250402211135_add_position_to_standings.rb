# frozen_string_literal: true

class AddPositionToStandings < ActiveRecord::Migration[8.0]
  def change
    add_column :standings, :position, :integer
  end
end
