# frozen_string_literal: true

require "test_helper"
require Rails.root.join('lib/clients/golaberto/client').to_s

class GolabertoClientTest < ActiveSupport::TestCase
  def setup
    @client = Clients::Golaberto::Client.new
  end

  test "simple matche" do
    matches = VCR.use_cassette("golaberto_matches_1") do
      @client.matches(league: :serie_b, season: 2006, round: 1)
    end

    expected = {
      date: DateTime.parse("2006-04-15T16:00:00-03:00"),
      round: 1,
      round_name: "Regular Season - 1",
      home_team: "América-RN",
      away_team: "Ituano-SP",
      home_goals: 1,
      away_goals: 2,
      status: 'Match Finished',
      result: "away"
    }

    assert_equal expected, matches.first
    assert_equal 10, matches.size
  end

  test "round with multiple dates" do # rubocop:disable Metrics/BlockLength
    matches = VCR.use_cassette("golaberto_matches_2") do
      @client.matches(league: :serie_b, season: 2006, round: 2)
    end

    test_matches = [
      {
        id: 0,
        expected: {
          date: DateTime.parse("2006-04-18T20:30:00-03:00"),
          round: 2,
          round_name: "Regular Season - 2",
          home_team: "Santo André-SP",
          away_team: "Marília-SP",
          home_goals: 1,
          away_goals: 1,
          status: 'Match Finished',
          result: "draw"
        }
      },
      {
        id: 2,
        expected: {
          date: DateTime.parse("2006-04-21T20:30:00-03:00"),
          round: 2,
          round_name: "Regular Season - 2",
          home_team: "CRB-AL",
          away_team: "Portuguesa-SP",
          home_goals: 1,
          away_goals: 0,
          status: 'Match Finished',
          result: "home"
        }
      },
      {
        id: 4,
        expected: {
          date: DateTime.parse("2006-04-22T16:00:00-03:00"),
          round: 2,
          round_name: "Regular Season - 2",
          home_team: "Atlético-MG",
          away_team: "Náutico-PE",
          home_goals: 3,
          away_goals: 1,
          status: 'Match Finished',
          result: "home"
        }
      },
      {
        id: 9,
        expected: {
          date: DateTime.parse("2006-04-23T16:00:00-03:00"),
          round: 2,
          round_name: "Regular Season - 2",
          home_team: "Ituano-SP",
          away_team: "Paulista-SP",
          home_goals: 1,
          away_goals: 1,
          status: 'Match Finished',
          result: "draw"
        }
      }
    ]
    test_matches.each do |test_match|
      assert_equal test_match[:expected], matches[test_match[:id]], "Match #{test_match[:id]} is not equal to expected"
    end
  end

  test "season has 380 matches" do
    matches = @client.matches(league: :serie_b, season: 2006)
    assert_equal 380, matches.size
  end
end
