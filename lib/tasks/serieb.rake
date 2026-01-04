# frozen_string_literal: true

namespace :serieb do # rubocop:disable Metrics/BlockLength
  desc "Import matches from serie b apifootball dataset"
  task apifootball: :environment do
    require "vcr"
    require "uri"
    VCR.configure do |config|
      config.cassette_library_dir = "lib/clients/api_football/vcr/serieb"
      config.hook_into :webmock
      config.ignore_request do |request|
        URI(request.uri).host == "api.honeybadger.io"
      end
    end

    # Started with two rounds only in 2006
    seasons = (2012..2014).to_a + (2016..2025).to_a
    seasons.each do |year|
      puts year

      VCR.use_cassette("apifootball_#{year}", record_on_error: false) do |_cassette|
        Season.apifootball_seed(league_id: 72, season_id: year)
      end
    end
  end

  desc "Import matches from golaberto"
  task golaberto: :environment do
    require "vcr"
    require "uri"
    VCR.configure do |config|
      config.cassette_library_dir = "lib/clients/golaberto/vcr/serieb"
      config.hook_into :webmock
    end

    seasons = (2006..2011).to_a + (2015..2015).to_a
    seasons.each do |year|
      puts "Year: #{year}"

      client = Clients::Golaberto::Client.new

      (1..38).each do |round|
        VCR.use_cassette("golaberto_#{year}_#{round}", record_on_error: false, record: :all) do |_cassette|
          matches = client.matches(league: :serie_b, season: year, round: round)
          puts "Round #{round} - Matches: #{matches.size}"
          matches.each do |match|
            puts "Importing match: #{match[:home_team]} #{match[:home_goals]} x " \
                 "#{match[:away_goals]} #{match[:away_team]} #{match[:date]}"
            client.import_match(league_id: 72, year: year, match: match)
          end
        end
      end
    end
  end

  desc "Correct teams names"
  task correct_teams: :environment do
    name_mapping = {
      "BOA" => "Boa Esporte",
      "Botafogo SP" => "Botafogo-SP",
      'Brasil DE Pelotas' => "Brasil de Pelotas",
      "Operario-PR" => "Operário",
      "Sao Bento" => "São Bento",
      "Sao Raimundo" => "São Raimundo"
    }

    name_mapping.each do |old_name, new_name|
      team = Team.find_by(name: old_name)
      team.update!(name: new_name)
    end
  end
end
