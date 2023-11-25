# frozen_string_literal: true

json.extract! season, :id, :year, :league_id, :created_at, :updated_at
json.url season_url(season, format: :json)
