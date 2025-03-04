# frozen_string_literal: true

namespace :import do # rubocop:disable Metrics/BlockLength
  desc "Import entire league data"
  task league: :environment do # rubocop:disable Metrics/BlockLength
    Team.find_or_create_by!(name: "America-RN", reference: 2233, logo: "https://media.api-sports.io/football/teams/2233.png")
    Team.find_or_create_by!(name: "Brasiliense", reference: 2208, logo: "https://media.api-sports.io/football/teams/2208.png")
    Team.find_or_create_by!(name: "Ipatinga", reference: 12_277, logo: "https://media.api-sports.io/football/teams/12277.png")
    Team.find_or_create_by!(name: "Santo André", reference: 10_003, logo: "https://media.api-sports.io/football/teams/10003.png")
    Team.find_or_create_by!(name: "São Caetano", reference: 7786, logo: "https://media.api-sports.io/football/teams/7786.png")

    references = {
      "America-MG" => "America Mineiro",
      "Atletico-GO" => "Atletico Goianiense",
      "Athletico-PR" => "Atletico Paranaense",
      "Barueri" => "Grêmio Barueri",
      "Botafogo-RJ" => "Botafogo",
      "Bragantino" => "RB Bragantino",
      "Chapecoense" => "Chapecoense-sc",
      "Fortaleza" => "Fortaleza EC",
      "Gremio Prudente" => "Grêmio Barueri",
      "Guarani" => "Guarani Campinas",
      "Nautico" => "Nautico Recife",
      "Santo Andre" => "Santo André",
      "Sao Caetano" => "São Caetano",
      "Sport" => "Sport Recife",
      "Vasco" => "Vasco DA Gama"
    }

    loader = Clients::Dataset::Loader.new
    missing = loader.teams_missing.sort

    missing.each do |team|
      next unless references[team]

      ApiClientTeam.create!(client_id: Clients::Dataset::CLIENT_ID, client_key: team,
                            team: Team.find_by(name: references[team]))
    end

    missing = loader.teams_missing.sort
    unless missing.empty?
      puts "Can't import league data. There are #{missing.length} missing teams:"
      puts "'#{missing.join("', '")}'"
      exit
    end

    puts "Importing matches..."
  end
end
