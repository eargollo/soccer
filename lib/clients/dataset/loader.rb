# frozen_string_literal: true

require "csv"

module Clients
  module Dataset
    CLIENT_ID = 3
    FILE = "lib/clients/dataset/campeonato-brasileiro-full.csv"

    class Loader
      def self.find_team(name)
        ApiClientTeam.find_by(client_id: CLIENT_ID, client_key: name)&.team
      end

      def self.guess_team(name)
        lookup = find_team(name)
        return lookup if lookup

        Team.find_by(name: name)
      end

      def initialize(file = nil)
        file ||= FILE
        @data = ::CSV.read(file, headers: true)
      end

      def matches
        @data
      end

      def teams
        teams = Set.new
        @data.each do |row|
          teams << row["mandante"]
          teams << row["visitante"]
        end

        teams.to_a
      end

      def teams_missing
        missing = []
        teams.each do |team|
          missing << team unless Loader.guess_team(team)
        end
        missing
      end
    end
  end
end
