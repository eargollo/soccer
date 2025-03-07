# frozen_string_literal: true

namespace :import do # rubocop:disable Metrics/BlockLength
  desc "Import entire league data"
  task league: :environment do # rubocop:disable Metrics/BlockLength
    cur_zone = Time.zone
    begin
      Time.zone = "America/Sao_Paulo"
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
      league = League.find_by(reference: 71)

      loader.matches.each_with_index do |m, i|
        team_home = Clients::Dataset::Loader.guess_team(m["mandante"])
        team_away = Clients::Dataset::Loader.guess_team(m["visitante"])
        year = m["data"][6..10].to_i
        # puts "year: #{year}"
        season = league.seasons.find_by(year: year)
        if season.nil?
          puts "Season #{year} is missing. Creating"
          season = league.seasons.create!(year: year)
        end

        date = Time.zone.local(year, m["data"][3..5].to_i, m["data"][0..2].to_i, m["hora"][0..2].to_i,
                               m["hora"][3..5].to_i)
        home_goals = m["mandante_Placar"].to_i
        away_goals = m["visitante_Placar"].to_i
        round = m["rodata"].to_i

        match = season.matches.find_by(team_home: team_home, team_away: team_away)
        if match.nil?
          if season.year >= 2010
            File.write('tmp/diffs.txt', "MISSING match #{date} #{team_home.name} #{home_goals} x #{away_goals} " \
                                        "#{team_away.name}\n",
                       mode: 'a+')

            puts "Match #{date} #{team_home.name} #{home_goals} x #{away_goals} #{team_away.name} is missing!!!"
          else
            puts "Match #{date} #{team_home.name} x #{team_away.name} is missing. Creating..."
            season.matches.create!(
              date: date,
              team_home: team_home,
              team_away: team_away,
              home_goals: home_goals,
              away_goals: away_goals,
              round: round,
              round_name: "Regular Season - #{round}",
              status: "Match Finished"
            )
          end
        else
          m_text = "Match #{match.season.year} round #{round} #{match.date} #{match.team_home.name} " \
                   "#{match.home_goals} x #{match.away_goals} #{match.team_away.name}"
          puts "#{m_text} already exists. Verifying..."
          if match.date != date
            File.write('tmp/diffs.txt', "#{m_text}: Date is incorrect: existing #{match.date} incoming #{date}\n",
                       mode: 'a+')
          end
          if match.home_goals != home_goals
            File.write('tmp/diffs.txt', "#{m_text}: Home goals is incorrect: existing #{match.home_goals} " \
                                        "incoming #{home_goals}\n",
                       mode: 'a+')
          end
          if match.away_goals != away_goals
            File.write('tmp/diffs.txt', "#{m_text}: Away goals is incorrect: existing #{match.away_goals} " \
                                        "incoming #{away_goals}\n",
                       mode: 'a+')
          end
          if match.status != "Match Finished"
            File.write('tmp/diffs.txt', "#{m_text}: Status is incorrect: existing #{match.status}\n",
                       mode: 'a+')
          end

          if match.round != round
            File.write('tmp/diffs.txt', "#{m_text}: Round is incorrect: existing #{match.round} incoming #{round}\n",
                       mode: 'a+')
            if season.year == 2010 && match.round == 38 && round == 1

              puts "Updating round from #{match.round} to #{round}"
              match.update!(round: round, round_name: "Regular Season - #{round}")
            end
          end
        end

        LeagueStanding.refresh if (i % 100).zero?
      end
      LeagueStanding.refresh
    end
  ensure
    Time.zone = cur_zone
  end
end
