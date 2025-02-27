# frozen_string_literal: true

class ApiClientTeam < ActiveRecord::Migration[8.0]
  def change
    create_table :api_client_teams do |t|
      t.references :team, null: false, foreign_key: { to_table: :teams }
      t.integer :client_id
      t.string :client_key

      t.timestamps
    end
  end
end
