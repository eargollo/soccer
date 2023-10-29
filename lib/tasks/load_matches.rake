# frozen_string_literal: true

require Rails.root.join("lib/clients/apifutebol/api_client.rb")

namespace :import do
  desc "Import championship matches"
  task matches: :environment do
    league = Client.new.league

    puts "Importing league '#{league.name}'(id=#{league.id})..."

    puts "Teams: #{league.teams.size}"
    teams = import_teams(league.teams)

    puts "Matches: #{league.matches.size}"
    import_matches(league.matches, teams)
  end
end

def import_teams(teams)
  list = {}
  teams.each do |t|
    team = import_team(t)
    list[team.reference] = team
  end
  list
end

def import_team(import)
  team = Team.find_by(reference: import.id)
  if team.nil?
    puts "Creating team #{import.name}..."
    team = Team.create(name: import.name, reference: import.id)
  end
  team
end

def import_matches(matches, teams) # rubocop:disable Metrics/AbcSize, Metrics/MethodLengthcs/MethodLength
  matches.each do |m| # rubocop:disable Metrics/BlockLength
    match = Match.find_by(reference: m.id)

    if match.nil?
      puts "Importing #{m.home_team} x #{m.away_team} at #{m.date}..."
      Match.create(
        date: m.date,
        team_home: teams[m.home_team_id],
        team_away: teams[m.away_team_id],
        status: m.status,
        home_goals: m.home_goals,
        away_goals: m.away_goals,
        result: m.result,
        reference: m.id
      )
    else
      Match.find_by(reference: m.id)
      match.update(
        date: m.date,
        team_home: teams[m.home_team_id],
        team_away: teams[m.away_team_id],
        status: m.status,
        home_goals: m.home_goals,
        away_goals: m.away_goals,
        result: m.result
      )
      if match.changed?
        puts "Updating #{match.team_home.name} x #{match.team_away.name}..."
        match.save
      end
    end
  end
end
