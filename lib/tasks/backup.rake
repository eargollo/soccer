# frozen_string_literal: true

namespace :backup do
  desc "Save teams to a file"
  task dump_teams: :environment do
    file = Rails.root.join("lib/clients/backup/teams_backup.json").to_s
    teams_data = Team.all.map do |team|
      team.attributes # Dynamically fetch all columns and their values
    end

    File.write(file, JSON.pretty_generate(teams_data))

    puts "Teams have been serialized to #{file}"
  end

  desc "Save leagues to a file"
  task dump_leagues: :environment do
    file = Rails.root.join("lib/clients/backup/leagues_backup.json").to_s
    leagues_data = League.all.map do |league|
      league.attributes # Dynamically fetch all columns and their values
    end

    File.write(file, JSON.pretty_generate(leagues_data))

    puts "Leagues have been serialized to #{file}"
  end

  desc "Save seasons to a file"
  task dump_seasons: :environment do
    file = Rails.root.join("lib/clients/backup/seasons_backup.json").to_s
    seasons_data = Season.all.map do |season|
      season.attributes # Dynamically fetch all columns and their values
    end

    File.write(file, JSON.pretty_generate(seasons_data))

    puts "Seasons have been serialized to #{file}"
  end

  desc "Save matches to a file"
  task dump_matches: :environment do
    file = Rails.root.join("lib/clients/backup/matches_backup.json").to_s
    matches_data = Match.all.map do |match|
      match.attributes # Dynamically fetch all columns and their values
    end

    File.write(file, JSON.pretty_generate(matches_data))

    puts "Matches have been serialized to #{file}"
  end
end
