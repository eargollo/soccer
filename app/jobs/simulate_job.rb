class SimulateJob < ApplicationJob
  queue_as :default

  # 45% probability of a win from the home team
  # at the competition today there is 45.56% home wins
  PROB_HOME_WIN_BAR = 0.45
  # 30% of probability of a draw and 25% of away wins
  # at the competition today there is 29.05% draw and 25.38% away wins
  PROB_DRAW_BAR = 0.75

  def perform(options)
    result = {}

    # Get matches to simulate
    matches = Match.pending

    # Define a baseline for simulation
    standing_start = Standing.all.each_with_object({}) do |standing, standing_start|
      standing_start[standing.team_id] = { wins: standing.wins, draws: standing.draws }
      result[standing.team_id] = Array.new(20, 0)
      puts "#{standing.team.name} has #{standing.wins} wins and #{standing.draws} draws"
    end

    puts "There are #{matches.count} matches to simulate"

    # Simulate
    options[:runs].times do
      sim_result = standing_start.deep_dup
      matches.each do |match|
        value = SecureRandom.random_number
        if value < PROB_HOME_WIN_BAR
          sim_result[match[:team_home_id]][:wins] += 1
        elsif value < PROB_DRAW_BAR
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
end
