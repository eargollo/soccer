# frozen_string_literal: true

class SimulateJob < ApplicationJob
  queue_as :default

  def perform(id) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    sim = Simulation.find(id)
    sim.start = Time.zone.now

    result = {}

    # Get matches to simulate
    matches = Match.pending

    # Define a baseline for simulation
    standing_start = Standing.all.map do |standing|
      result[standing.team_id] = Array.new(20, 0)
      { wins: standing.wins, draws: standing.draws }
    end

    standing_start = Standing.all.each_with_object({}) do |standing, ss|
      ss[standing.team_id] = { wins: standing.wins, draws: standing.draws }
      result[standing.team_id] = Array.new(20, 0)
    end

    # Simulate
    sim.runs.times do
      sim_result = standing_start.deep_dup
      matches.each do |match|
        value = SecureRandom.random_number
        if value < match.prob_win
          sim_result[match.team_home_id][:wins] += 1
        elsif value < match.prob_not_loss
          sim_result[match.team_home_id][:draws] += 1
          sim_result[match.team_away_id][:draws] += 1
        else
          sim_result[match.team_away_id][:wins] += 1
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
      sim.standings.create(
        team_id:,
        champion: (team_result[0].to_f * 100) / sim.runs,
        promotion: (team_result[0] + team_result[1] + team_result[2] + team_result[4]).to_f * 100 / sim.runs,
        relegation: (team_result[16] + team_result[17] + team_result[18] + team_result[19]).to_f * 100 / sim.runs
      )
      team_result.each_with_index do |count, position|
        sim.standing_positions.create(team_id:, position: position + 1, count:)
      end
    end
    sim.finish = Time.zone.now
    sim.save
  end
end
