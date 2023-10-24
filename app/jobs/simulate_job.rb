class SimulateJob < ApplicationJob
  queue_as :default

  def perform(options)
    result = {}

    # Get matches to simulate
    matches = Match.pending

    # Define a baseline for simulation
    standings = Standing.all.each_with_object({}) do |standing, standing_start|
      standing_start[standing.team_id] = { wins: standing.wins, draws: standing.draws }
      result[standing.team_id] = Array.new(20, 0)
      puts "#{standing.team.name} has #{standing.wins} wins and #{standing.draws} draws"
    end

    puts "There are #{matches.count} matches to simulate"

    # Probabilities
    win_lim = 0.45
    draw_lim = 0.7

    # Simulate
    options[:runs].times do
      sim_result = deep_clone(standing_start)
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
      srt_standing = []
      sim_result.each do |team_id, team_result|
        srt_standing << { team_id:, wins: team_result[:wins], draws: team_result[:draws],
                          points: team_result[:wins] * 3 + team_result[:draws] }
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

  def deep_clone(object)
    if object.is_a?(Hash)
      object.each_with_object({}) do |(key, value), new_hash|
        new_hash[key] = deep_clone(value)
      end
    elsif object.is_a?(Array)
      object.map { |item| deep_clone(item) }
    else
      object
    end
  end
end
