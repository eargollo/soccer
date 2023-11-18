# frozen_string_literal: true

require "test_helper"
require Rails.root.join('lib/clients/apifootball/client').to_s
require Rails.root.join('lib/clients/soccerdataapi/client').to_s

class LoadLeagueJobTest < ActiveJob::TestCase
  TEST_LEAGUE_ID = 72
  TEST_LEAGUE_SEASON = 2023

  def setup
    @client = SoccerAPI::APIFootball::Client.new(ENV.fetch("APIFOOTBALL_TOKEN", nil))
  end

  test "raises error if not autheticated" do
    client = SoccerAPI::APIFootball::Client.new("")
    VCR.use_cassette("error") do
      assert_raises RuntimeError do
        client.matches(league_id: TEST_LEAGUE_ID, season: TEST_LEAGUE_SEASON)
      end
    end
  end

  test "league has 380 matches" do
    expected_firsts = [
      { reference: 1_006_447,
        date: DateTime.parse("2023-04-14T22:00:00+00:00"),
        round: 1,
        home_team_reference: 138,
        away_team_reference: 145,
        home_goals: 4,
        away_goals: 1,
        status: "FT" },
      { reference: 1_006_448,
        date: DateTime.parse("2023-04-15T19:00:00+00:00"),
        round: 1,
        home_team_reference: 142,
        away_team_reference: 7834,
        home_goals: 2,
        away_goals: 1,
        status: "FT" }
    ]
    VCR.use_cassette("league") do
      matches = @client.matches(league_id: TEST_LEAGUE_ID, season: TEST_LEAGUE_SEASON)
      assert_equal 380, matches.size
      assert_equal expected_firsts, matches.first(expected_firsts.size)
    end
  end
end
