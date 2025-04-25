# frozen_string_literal: true

# == Schema Information
#
# Table name: simulations
#
#  id         :bigint           not null, primary key
#  finish     :datetime
#  name       :string
#  runs       :integer
#  start      :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  season_id  :bigint           default(1), not null
#
# Indexes
#
#  index_simulations_on_season_id  (season_id)
#
# Foreign Keys
#
#  fk_rails_...  (season_id => seasons.id)
#
require "test_helper"

class SimulationTest < ActiveSupport::TestCase
  def setup
    @season = seasons(:season1)
    @simulation = @season.simulations.new(name: "Simulation 1", runs: 1000)

    @teams = [teams(:barcelona), teams(:madrid), teams(:espanyol)]

    @teams.each do |home|
      @teams.each do |away|
        @season.matches.create(team_home: home, team_away: away) if home != away
      end
    end
  end

  test "stablished a simulation baseline" do
    @season.matches.first.update(status: 'Match Finished', home_goals: 2, away_goals: 1)
    @season.matches.second.update(status: 'Match Finished', home_goals: 2, away_goals: 0)
    @season.matches.third.update(status: 'Match Finished', home_goals: 1, away_goals: 1)
    result, standing_start = @simulation.send(:baseline)

    @teams.each do |team|
      assert_equal Array.new(20, 0), result[team.id]
    end

    assert_equal({ wins: 2, draws: 1 }, standing_start[@teams[0].id])
    assert_equal({ wins: 0, draws: 1 }, standing_start[@teams[1].id])
    assert_equal({ wins: 0, draws: 0 }, standing_start[@teams[2].id])
  end

  test "stablishes a simulation baseline with match presets" do
    @season.matches.first.update(status: 'Match Finished', home_goals: 2, away_goals: 1)
    @season.matches.second.update(status: 'Match Finished', home_goals: 2, away_goals: 0)
    @season.matches.third.update(status: 'Match Finished', home_goals: 1, away_goals: 1)
    @simulation.save
    @simulation.simulation_match_presets.create(match: @season.matches.first, result: "away")
    @simulation.simulation_match_presets.create(match: @season.matches.last, result: "home")

    _, standing_start = @simulation.send(:baseline)

    # B x [M]
    # [B] x E
    # M [x] B
    # M x E
    # E X B
    # [E] x M

    assert_equal({ wins: 1, draws: 1 }, standing_start[@teams[0].id])
    assert_equal({ wins: 1, draws: 1 }, standing_start[@teams[1].id])
    assert_equal({ wins: 1, draws: 0 }, standing_start[@teams[2].id])
  end

  test "properly aggregates results" do
    ss = {
      Team.second.id => { wins: 1, draws: 1, points: 4 },
      Team.third.id => { wins: 0, draws: 1, points: 1 },
      Team.first.id => { wins: 4, draws: 0, points: 12 }
    }
    result = {
      Team.first.id => Array.new(20, 0),
      Team.second.id => Array.new(20, 0),
      Team.third.id => Array.new(20, 0)
    }
    expected = result.deep_dup
    expected[Team.first.id][0] = 1
    expected[Team.second.id][1] = 1
    expected[Team.third.id][2] = 1
    @simulation.send(:aggregate, ss, result)
    assert_equal expected, result
  end
end
