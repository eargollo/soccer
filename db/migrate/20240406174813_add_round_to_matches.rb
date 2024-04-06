# frozen_string_literal: true

class AddRoundToMatches < ActiveRecord::Migration[7.1]
  def change
    add_column :matches, :round, :integer
    add_column :matches, :round_name, :string
  end
end
