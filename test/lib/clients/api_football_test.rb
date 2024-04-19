# frozen_string_literal: true

require "test_helper"
require Rails.root.join('lib/clients/api_football/client').to_s
require Rails.root.join('lib/clients/soccer_data_api/client').to_s

class LoadLeagueJobTest < ActiveJob::TestCase
  TEST_LEAGUE_ID = 72
  TEST_LEAGUE_SEASON = 2023

  def setup
    @client = Clients::ApiFootball::Client.new(Rails.application.credentials.api_football.token)
  end

  test "raises error if not autheticated" do
    client = Clients::ApiFootball::Client.new("")
    VCR.use_cassette("error") do
      assert_raises RuntimeError do
        client.matches(league_id: TEST_LEAGUE_ID, season: TEST_LEAGUE_SEASON)
      end
    end
  end

  test "league has 380 matches" do # rubocop:disable Metrics/BlockLength
    league = {
      "id" => 72,
      "name" => "Serie B",
      "country" => "Brazil",
      "logo" => "https://media-4.api-sports.io/football/leagues/72.png",
      "flag" => "https://media-4.api-sports.io/flags/br.svg",
      "season" => 2023,
      "round" => "Regular Season - 1"
    }
    expected_firsts = [
      { reference: 1_006_447,
        date: DateTime.parse("2023-04-14T22:00:00+00:00"),
        round: 1,
        round_name: "Regular Season - 1",
        league:,
        home_team: {
          "id" => 138,
          "name" => "Guarani Campinas",
          "logo" => "https://media-4.api-sports.io/football/teams/138.png",
          "winner" => true
        },
        away_team: {
          "id" => 145,
          "name" => "Avai",
          "logo" => "https://media-4.api-sports.io/football/teams/145.png",
          "winner" => false
        },
        home_goals: 4,
        away_goals: 1,
        status: "finished",
        result: "home" },
      { reference: 1_006_448,
        date: DateTime.parse("2023-04-15T19:00:00+00:00"),
        round: 1,
        round_name: "Regular Season - 1",
        league:,
        home_team: {
          "id" => 142,
          "name" => "Vila Nova",
          "logo" => "https://media-4.api-sports.io/football/teams/142.png",
          "winner" => true
        },
        away_team: {
          "id" => 7834,
          "name" => "Novorizontino",
          "logo" => "https://media-4.api-sports.io/football/teams/7834.png",
          "winner" => false
        },
        home_goals: 2,
        away_goals: 1,
        status: "finished",
        result: "home" }
    ]
    VCR.use_cassette("league") do
      matches = @client.matches(league_id: TEST_LEAGUE_ID, season: TEST_LEAGUE_SEASON)
      assert_equal 380, matches.size
      assert_equal expected_firsts, matches.first(expected_firsts.size)
    end
  end
end
