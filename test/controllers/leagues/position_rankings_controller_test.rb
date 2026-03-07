# frozen_string_literal: true

require "test_helper"

module Leagues
  class PositionRankingsControllerTest < ActionDispatch::IntegrationTest
    def setup
      @league = leagues(:a_league)
    end

    test "show returns success" do
      get position_ranking_league_path(@league)
      assert_response :success
    end

    test "show displays league name and position ranking content" do
      get position_ranking_league_path(@league)
      assert_match @league.name, response.body
      assert_match(/position ranking|medals|finished seasons/i, response.body)
    end

    test "show displays table or empty message" do
      get position_ranking_league_path(@league)
      has_table = response.body.include?("<table") && response.body.include?("Pos</th>")
      has_empty_message = response.body.include?("No finished seasons for this league yet")
      assert has_table || has_empty_message, "Expected table or empty message"
    end

    test "show accepts positions param and renders" do
      get position_ranking_league_path(@league), params: { positions: 5 }
      assert_response :success
      # With positions=5, header has Pos, Team, 1, 2, 3, 4, 5
      assert_match @league.name, response.body
      assert response.body.include?("5</th>"), "Expected column 5 in header"
    end
  end
end
