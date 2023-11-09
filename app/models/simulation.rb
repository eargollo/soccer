# frozen_string_literal: true

class Simulation < ApplicationRecord
  has_many :simulation_standings, dependent: :destroy
  has_many :simulation_standing_positions, dependent: :destroy
  has_many :simulation_match_presets, dependent: :destroy

  after_commit -> { SimulateJob.perform_later(id) }, on: :create

  def run
    tag_start

    # Define a baseline for simulation
    result, standing_start = baseline

    # Get matches to simulate
    matches = Match.pending

    # Simulate
    runs.times do
      # Result for this simulation instance
      sim_result = simulate_matches(matches, standing_start)

      # Aggregate the result
      aggregate(sim_result, result)
    end

    # Save the result
    save_result(result)

    tag_finish
  end

  private

  def schedule; end

  def tag_start
    # In the future we may want to clean the results and re-run the simulation
    raise "Simulation have either already started or been executed" unless start.nil?

    update!(start: Time.zone.now)
  end

  def baseline
    result = {}
    standing_start = Standing.all.each_with_object({}) do |standing, ss|
      ss[standing.team_id] = { wins: standing.wins, draws: standing.draws }
      result[standing.team_id] = Array.new(20, 0)
    end
    # Apply match presets
    simulation_match_presets.each do |preset|
      if preset.match.finished?
        # Take out original result if match was finished
        standing_start[preset.match.team_home_id][:wins] -= 1 if preset.match.result == "home"
        standing_start[preset.match.team_away_id][:wins] -= 1 if preset.match.result == "away"
        if preset.match.result == "draw"
          standing_start[preset.match.team_home_id][:draws] -= 1
          standing_start[preset.match.team_away_id][:draws] -= 1
        end
      end

      # Apply preset
      standing_start[preset.match.team_home_id][:wins] += 1 if preset.result == "home"
      standing_start[preset.match.team_away_id][:wins] += 1 if preset.result == "away"
      if preset.result == "draw"
        standing_start[preset.match.team_home_id][:draws] += 1
        standing_start[preset.match.team_away_id][:draws] += 1
      end
    end
    [result, standing_start]
  end

  def simulate_matches(matches, standing_start) # rubocop:disable Metrics/AbcSize
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
    sim_result
  end

  def aggregate(sim_result, result)
    # Get standing
    standing = sim_result.map do |team_id, team_result|
      { team_id:, wins: team_result[:wins], draws: team_result[:draws],
        points: (team_result[:wins] * 3) + team_result[:draws] }
    end
    # Sort standing
    # TODO: Add goals to the sort
    standing.sort_by! { |team| [team[:points], team[:wins]] }.reverse!
    # Aggregate
    standing.each_with_index do |team, index|
      result[team[:team_id]][index] += 1
    end
    result
  end

  def save_result(result) # rubocop:disable Metrics/AbcSize
    result.each do |team_id, team_result|
      simulation_standings.create(
        team_id:,
        champion: (team_result[0].to_f * 100) / runs,
        promotion: (team_result[0] + team_result[1] + team_result[2] + team_result[4]).to_f * 100 / runs,
        relegation: (team_result[16] + team_result[17] + team_result[18] + team_result[19]).to_f * 100 / runs
      )
      team_result.each_with_index do |count, position|
        simulation_standing_positions.create(team_id:, position: position + 1, count:)
      end
    end
  end

  def tag_finish
    update!(finish: Time.zone.now)
  end
end
