# frozen_string_literal: true

require "csv"

module Clients
  module Dataset
    CLIENT_ID = 3
    FILE =

      class Loader
        def self.find_team(name)
          ApiClientTeam.find_by(client_id: CLIENT_ID, client_key: name)&.team
        end

        def self.guess_team(name)
          Team.find_by(name: name)
        end

        def initialize
          @data = ::CSV.read("lib/clients/dataset/campeonato-brasileiro-full.csv", headers: true)
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

          # puts "Teams: #{teams.to_a.sort}"

          teams.to_a
        end
      end
  end
end
