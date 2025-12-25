# frozen_string_literal: true

namespace :backup do # rubocop:disable Metrics/BlockLength
  desc "Backup leagues, teams, seasons and matches to a dsl file"
  task save: :environment do
    file = Rails.root.join("lib/clients/backup/backup.rb").to_s

    File.open(file, "w") do |f|
      Team.order(Arel.sql("CASE WHEN name = 'Vitória' THEN 0 ELSE 1 END, name")).each do |team|
        f.puts "team name: '#{team.name}', reference: #{team.reference}, logo: '#{team.logo}'"
      end
      League.order(:reference).each do |league|
        f.puts "league country: '#{league.country}', flag: '#{league.flag}', logo: '#{league.logo}', " \
               "name: '#{league.name}', reference: #{league.reference}, seasons: #{league.seasons.count} do"

        league.seasons.order(year: :asc).each do |season|
          f.puts "  season year: #{season.year}, active: #{season.active}, matches: #{season.matches.count} do"
          season.matches.order(round: :asc, date: :asc).each do |match|
            home_goals_str = match.home_goals.present? ? ", home_goals: #{match.home_goals}" : ""
            away_goals_str = match.away_goals.present? ? ", away_goals: #{match.away_goals}" : ""
            reference_str = match.reference.present? ? ", reference: #{match.reference}" : ""
            f.puts "    match date: '#{match.date.iso8601}', round: #{match.round}, " \
                   "round_name: '#{match.round_name}', " \
                   "team_home: '#{match.team_home.name}', team_away: '#{match.team_away.name}', " \
                   "status: '#{match.status}', result: '#{match.result}'" \
                   "#{home_goals_str}#{away_goals_str}#{reference_str}"
          end

          f.puts "  end"
        end
        f.puts "end"
      end
    end
  end

  desc "Load leagues, teams, seasons and matches from backup file"
  task load: :environment do
    file = ENV["FILE"] || Rails.root.join("lib/clients/backup/backup.rb").to_s

    puts "Loading backup from #{file}"

    observer = Object.new.tap do |obs|
      def obs.season_created(season)
        puts "#{season.league.name} #{season.year}"
      end
    end

    client = Clients::Backup::Client.new(file, observer: observer)
    client.load

    puts "Backup loaded successfully"
  end
end
