# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Seed admin user
if User.find_by(email: Rails.application.credentials.admin_user.email).nil?
  User.create(
    name: Rails.application.credentials.admin_user.name,
    email: Rails.application.credentials.admin_user.email,
    password: Rails.application.credentials.admin_user.password,
    password_confirmation: Rails.application.credentials.admin_user.password
  )
end

ActiveRecord::Base.connection.execute <<-SQL.squish
  CREATE MATERIALIZED VIEW IF NOT EXISTS league_standings_matview AS
    SELECT  teams.id as team_id,
            seasons.league_id as league_id,
            sum(standings.points) as points,
            sum(standings.matches) as matches,
            sum(standings.wins) as wins,
            sum(standings.draws) as draws,
            sum(standings.losses) as losses,
            sum(standings.goals_pro) as goals_pro,
            sum(standings.goals_against) as goals_against,
            count(seasons.id) as seasons,
            max(seasons.year) as last_season
      FROM teams, standings, seasons
      WHERE teams.id = standings.team_id AND standings.season_id = seasons.id
      GROUP BY teams.id, seasons.league_id;
SQL
