# frozen_string_literal: true

class AddLogoToTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :logo, :string
  end
end
