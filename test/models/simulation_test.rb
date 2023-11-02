# frozen_string_literal: true

require "test_helper"

class SimulationTest < ActiveSupport::TestCase
  def setup
    @simulation = Simulation.new(name: "Simulation 1", runs: 1000)

    @teams = [teams(:barcelona), teams(:madrid), teams(:espanyol)]

    @teams.each do |home|
      @teams.each do |away|
        Match.create(team_home: home, team_away: away) if home != away
      end
    end
  end

  test "stablished a simulation baseline" do
    Match.first.update(status: "finished", home_goals: 2, away_goals: 1)
    Match.second.update(status: "finished", home_goals: 2, away_goals: 0)
    Match.third.update(status: "finished", home_goals: 1, away_goals: 1)
    result, standing_start = @simulation.send(:baseline)

    @teams.each do |team|
      assert_equal Array.new(20, 0), result[team.id]
    end

    assert_equal({ wins: 2, draws: 1 }, standing_start[@teams[0].id])
    assert_equal({ wins: 0, draws: 1 }, standing_start[@teams[1].id])
    assert_equal({ wins: 0, draws: 0 }, standing_start[@teams[2].id])
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
