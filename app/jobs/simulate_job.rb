# frozen_string_literal: true

class SimulateJob < ApplicationJob
  queue_as :default

  def perform(options) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    result = {}

    # Get matches to simulate
    matches = Match.pending.map do |match|
      { team_home_id: match.team_home_id, team_away_id: match.team_away_id, probability: match.probability }
    end

    # Define a baseline for simulation
    standing_start = Standing.all.map do |standing|
      result[standing.team_id] = Array.new(20, 0)
      { wins: standing.wins, draws: standing.draws }
    end

    standing_start = Standing.all.each_with_object({}) do |standing, ss|
      ss[standing.team_id] = { wins: standing.wins, draws: standing.draws }
      result[standing.team_id] = Array.new(20, 0)
      puts "#{standing.team.name} has #{standing.wins} wins and #{standing.draws} draws"
    end

    puts "There are #{matches.count} matches to simulate"

    # Simulate
    options[:runs].times do
      sim_result = standing_start.deep_dup
      matches.each do |match|
        value = SecureRandom.random_number
        if value < match[:probability][0]
          sim_result[match[:team_home_id]][:wins] += 1
        elsif value < match[:probability][0] + match[:probability][1]
          sim_result[match[:team_home_id]][:draws] += 1
          sim_result[match[:team_away_id]][:draws] += 1
        else
          sim_result[match[:team_away_id]][:wins] += 1
        end
      end
      srt_standing = []
      sim_result.each do |team_id, team_result|
        srt_standing << { team_id:, wins: team_result[:wins], draws: team_result[:draws],
                          points: (team_result[:wins] * 3) + team_result[:draws] }
      end
      srt_standing.sort_by! { |team| [team[:points], team[:wins]] }.reverse!
      srt_standing.each_with_index do |team, index|
        result[team[:team_id]][index] += 1
      end
    end
    result.each do |team_id, team_result|
      puts "#{Team.find(team_id).name}: #{team_result}"
    end
  end
end
