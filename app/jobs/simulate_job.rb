# frozen_string_literal: true

class SimulateJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    matches = []
    Match.where.not(status: 'finished').each do |match|
      matches << { team_home_id: match.team_home_id, team_away_id: match.team_away_id }
    end

    sim_result = {}
    Standing.all.each do |team|
      sim_result[team.id] = { wins: team.wins, draws: team.draws }
    end

    puts "There are #{matches.count} matches to simulate"
    puts "Sim start: #{sim_result.inspect}"

    win_lim = 0.45
    draw_lim = 0.7
    matches.each do |match|
      value = SecureRandom.random_number
      if value < win_lim
        sim_result[match[:team_home_id]][:wins] += 1
      elsif value < draw_lim
        sim_result[match[:team_home_id]][:draws] += 1
        sim_result[match[:team_away_id]][:draws] += 1
      else
        sim_result[match[:team_away_id]][:wins] += 1
      end
    end
    result = []
    sim_result.each do |team_id, team_result|
      result << { team_id:, wins: team_result[:wins], draws: team_result[:draws],
                  points: team_result[:wins] * 3 + team_result[:draws] }
    end
    result.sort_by! { |team| [team[:points], team[:wins]] }.reverse!
    puts "Sim end: #{result.inspect}"
  end
end
