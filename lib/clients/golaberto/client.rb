# frozen_string_literal: true

# API Football has the advantage of giving the round of the match

require Rails.root.join('lib/clients/interface').to_s
require 'uri'
require 'net/http'
require 'openssl'

module Clients
  module Golaberto
    class Client # rubocop:disable Metrics/ClassLength
      include Clients::Interface

      URL = "https://www.golaberto.com.br/championship/show/"

      TEAM_MAPPING = {
        "Boa Esporte-MG" => "BOA",
        "Sampaio Corrêa-MA" => "Sampaio Correa",
        "São Raimundo-AM" => "Sao Raimundo",
        "Sport-PE" => "Sport Recife"
      }.freeze

      FILE_TEAM_MAPPING = Rails.root.join("lib/clients/golaberto/teams.txt").to_s

      LEAGUES = {
        serie_b: {
          2006 => "17-brasil-campeonato-brasileiro-serie-b-2006/games/33-turno-e-returno",
          2007 => "27-brasil-campeonato-brasileiro-serie-b-2007/games/76-turno-e-returno",
          2008 => "87-brasil-campeonato-brasileiro-serie-b-2008/games/289-fase-unica",
          2009 => "160-brasil-campeonato-brasileiro-serie-b-2009/games/515-turno-e-returno",
          2010 => "229-brasil-campeonato-brasileiro-serie-b-2010/games/769-turno-e-returno",
          2011 => "345-brasil-campeonato-brasileiro-serie-b-2011/games/1233-fase-unica",
          2015 => "639-brasil-campeonato-brasileiro-serie-b-2015/games/2230-turno-e-returno"
        }
      }.freeze

      def initialize
        @mapping = TEAM_MAPPING.dup
        url = URI(URL)
        @http = Net::HTTP.new(url.host, url.port)
        @http.use_ssl = true
        @http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        return unless File.exist?(FILE_TEAM_MAPPING)

        File.read(FILE_TEAM_MAPPING).each_line do |line|
          name, team_name = line.split("=>").map(&:strip)
          @mapping[name] = team_name
        end
      end

      def matches(league:, season:, round:) # rubocop:disable Metrics/AbcSize
        matches = []
        url = URI("#{URL}/#{LEAGUES[league][season]}/round/#{round}")
        response = @http.request(request(url))
        doc = Nokogiri::HTML(response.body.force_encoding("UTF-8"))

        round_text = doc.css('.game_round').text
        round_number = round_text[/(\d+)/].to_i

        # Get all game_date and table_row elements in document order
        current_date = nil
        elements = doc.css('.game_date, .table_row')

        elements.each do |element|
          if element.classes.include?('game_date')
            # Parse date from "18/04/2006 - Terça"
            date_text = element.text.strip
            date_match = date_text.match(%r{(\d{2}/\d{2}/\d{4})})
            raise "Error: could not parse date from #{date_text}" unless date_match

            current_date = date_match[1]
          elsif element.classes.include?('table_row')
            # Parse match data
            match = parse_match_row(element, current_date, round_number)
            matches << match if match
          end
        end
        matches
      end

      def import_match(league_id:, year:, match:) # rubocop:disable Metrics/AbcSize
        league = League.find_by(reference: league_id)
        raise "Error: league not found" if league.nil?

        season = league.seasons.find_or_create_by(year: year)

        home_team = guess_team(match[:home_team])
        raise "Error: home team #{match[:home_team]} not found" if home_team.nil?

        away_team = guess_team(match[:away_team])
        raise "Error: away team #{match[:away_team]} not found" if away_team.nil?

        raise "Error: date is empty" if match[:date].nil?

        season.matches.find_or_create_by(
          date: match[:date],
          team_home: home_team,
          team_away: away_team,
          round: match[:round],
          round_name: "Regular Season - #{match[:round]}",
          home_goals: match[:home_goals],
          away_goals: match[:away_goals],
          status: 'Match Finished',
          result: match[:result]
        )
      end

      def guess_team(name) # rubocop:disable Metrics/AbcSize
        name = @mapping[name] if @mapping.key?(name)

        team = Team.find_by(name: name)
        return team if team

        single_name = name.split('-').first.strip
        team = Team.find_by(name: single_name)

        if team
          puts "Should I match #{name} with #{team.name}? (y/n)" # rubocop:disable Rails/Output
          answer = $stdin.gets.chomp
          if answer == 'y'
            File.write(FILE_TEAM_MAPPING, "#{name}=>#{team.name}\n", mode: 'a')
            @mapping[name] = team.name
            return team
          end
        end

        find_and_add_team_api_football(name, single_name)
      end

      private

      def find_and_add_team_api_football(name, single_name) # rubocop:disable Metrics/AbcSize
        client = Clients::ApiFootball::Client.new(Rails.application.credentials.api_football.token)
        api_football_team = client.team(name) || client.team(single_name)

        if api_football_team
          api_football_team = api_football_team["team"]

          puts "Should I match #{name} with API Football team #{api_football_team['name']} ? (y/n)" # rubocop:disable Rails/Output
          answer = $stdin.gets.chomp
          if answer == 'y'
            team = Team.create!(
              name: api_football_team["name"],
              reference: api_football_team["id"],
              logo: api_football_team["logo"]
            )

            return team
          end
        end

        nil
      end

      def parse_match_row(row_element, date_str, round_number) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        raise "Error: match without date" unless date_str

        # Parse date and time
        time_text = row_element.at_css('.game_time')&.text&.strip
        raise "Error: match without time" unless time_text

        date = parse_datetime(date_str, time_text)

        # Get team names
        home_name = row_element.at_css('.home_name')&.text&.strip
        away_name = row_element.at_css('.away_name')&.text&.strip

        # Get scores (may be empty for future matches)
        home_score_text = row_element.at_css('.home_score')&.text&.strip
        away_score_text = row_element.at_css('.away_score')&.text&.strip
        raise "Error: home score text is empty" unless home_score_text
        raise "Error: away score text is empty" unless away_score_text

        home_goals = home_score_text.match?(/\d+/) ? home_score_text.to_i : raise("Error: home score is not a number")
        away_goals = away_score_text.match?(/\d+/) ? away_score_text.to_i : raise("Error: away score is not a number")

        result = if home_goals == away_goals
                   'draw'
                 elsif home_goals > away_goals
                   'home'
                 else
                   'away'
                 end

        {
          date: date,
          round: round_number,
          round_name: "Regular Season - #{round_number}",
          home_team: home_name,
          away_team: away_name,
          home_goals: home_goals,
          away_goals: away_goals,
          status: 'Match Finished',
          result: result
        }
      end

      def parse_datetime(date_str, time_str)
        # Parse "18/04/2006" and "20:30"
        day, month, year = date_str.split('/').map(&:to_i)
        hour, minute = time_str.split(':').map(&:to_i)

        # Assume Brazil timezone (UTC-3)
        DateTime.new(year, month, day, hour, minute, 0, '-00:00')
      end

      def request(url)
        Net::HTTP::Get.new(url)
      end
    end
  end
end
