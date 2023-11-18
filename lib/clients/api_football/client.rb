# frozen_string_literal: true

require Rails.root.join('lib/clients/interface').to_s
require 'uri'
require 'net/http'
require 'openssl'

module Clients
  module ApiFootball
    class Client
      include Clients::Interface

      URL = "https://v3.football.api-sports.io"

      def initialize(api_key)
        @api_key = api_key

        url = URI(URL)
        @http = Net::HTTP.new(url.host, url.port)
        @http.use_ssl = true
        @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      def matches(league_id:, season:)
        url = URI("#{URL}/fixtures?season=#{season}&league=#{league_id}")

        response = @http.request(request(url))

        if response.code != "200"
          raise "Request failed with HTTP status code: #{response.code}\nResponse Body: #{response.body}"
        end

        data = JSON.parse(response.read_body)
        raise "Request failed with errors: #{data['errors']}" unless data["errors"].empty?

        convert_matches(data)
      end

      private

      # Needs of a match:
      # - date
      # - round
      # - home_team_reference
      # - away_team_reference
      # - home_goals
      # - away_goals
      # - status
      # - reference
      def convert_matches(data) # rubocop:disable Metrics/AbcSize
        data['response'].map do |m|
          {
            reference: m['fixture']['id'],
            date: DateTime.parse(m['fixture']['date']),
            round: m['league']['round'][/(\d+)/].to_i,
            home_team_reference: m['teams']['home']['id'],
            away_team_reference: m['teams']['away']['id'],
            home_goals: m['goals']['home'],
            away_goals: m['goals']['away'],
            status: m['fixture']['status']['short']
          }
        end
      end

      def request(url)
        request = Net::HTTP::Get.new(url)
        request["x-rapidapi-host"] = 'v3.football.api-sports.io'
        request["x-rapidapi-key"] = @api_key
        request
      end
    end
  end
end
