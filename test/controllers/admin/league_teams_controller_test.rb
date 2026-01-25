# frozen_string_literal: true

require "test_helper"

module Admin
  class LeagueTeamsControllerTest < ActionDispatch::IntegrationTest # rubocop:disable Metrics/ClassLength
    include Devise::Test::IntegrationHelpers

    def setup # rubocop:disable Metrics/AbcSize
      @user = users(:one)
      @league = leagues(:a_league)
      @team = teams(:barcelona)
      @team2 = teams(:madrid)

      # Create LeagueTeam records
      @league_team = LeagueTeam.create!(
        league: @league,
        team: @team,
        home_prob_win: 0.5.to_d,
        home_prob_draw: 0.3.to_d,
        home_prob_loss: 0.2.to_d,
        away_prob_win: 0.4.to_d,
        away_prob_draw: 0.3.to_d,
        away_prob_loss: 0.3.to_d
      )
      @league_team2 = LeagueTeam.create!(
        league: @league,
        team: @team2,
        home_prob_win: 0.6.to_d,
        home_prob_draw: 0.2.to_d,
        home_prob_loss: 0.2.to_d,
        away_prob_win: 0.3.to_d,
        away_prob_draw: 0.3.to_d,
        away_prob_loss: 0.4.to_d
      )
    end

    test "index displays teams with probabilities" do
      sign_in @user

      get admin_league_league_teams_path(admin_league_id: @league.id)

      assert_response :success
      assert_select 'table' do
        assert_select 'tr', count: 3 # header + 2 teams
      end
      assert_match @team.name, response.body
      assert_match @team2.name, response.body
    end

    test "index requires authentication" do
      get admin_league_league_teams_path(admin_league_id: @league.id)

      assert_redirected_to new_user_session_path
    end

    test "show displays team details" do
      sign_in @user

      get admin_league_league_team_path(admin_league_id: @league.id, id: @league_team.id)

      assert_response :success
      assert_match @team.name, response.body
      assert_match '0.5', response.body # home_prob_win
      assert_match '0.3', response.body # home_prob_draw
      assert_match '0.2', response.body # home_prob_loss
    end

    test "show requires authentication" do
      get admin_league_league_team_path(admin_league_id: @league.id, id: @league_team.id)

      assert_redirected_to new_user_session_path
    end

    test "recalculate triggers service for entire league" do
      sign_in @user

      # Create a finished match to test recalculation
      season = @league.seasons.first
      match = season.matches.create!(
        team_home: @team,
        team_away: @team2,
        date: 1.day.ago,
        status: 'Not Started'
      )
      match.update_columns( # rubocop:disable Rails/SkipsModelValidations
        status: 'Match Finished',
        result: 'home',
        home_goals: 1,
        away_goals: 0
      )

      original_prob = @league_team.reload.home_prob_win

      post recalculate_admin_league_league_teams_path(admin_league_id: @league.id)

      # Probabilities should have been recalculated
      @league_team.reload
      assert_not_equal original_prob, @league_team.home_prob_win

      assert_redirected_to admin_league_league_teams_path(admin_league_id: @league.id)
      assert_match(/recalculated/i, flash[:notice])
    end

    test "recalculate triggers service for specific team" do
      sign_in @user

      # Create a finished match
      season = @league.seasons.first
      match = season.matches.create!(
        team_home: @team,
        team_away: @team2,
        date: 1.day.ago,
        status: 'Not Started'
      )
      match.update_columns( # rubocop:disable Rails/SkipsModelValidations
        status: 'Match Finished',
        result: 'home',
        home_goals: 1,
        away_goals: 0
      )

      original_prob = @league_team2.reload.home_prob_win

      post recalculate_admin_league_league_team_path(admin_league_id: @league.id, id: @league_team.id)

      # @team's probabilities should have changed
      assert_not_equal original_prob, @league_team.reload.home_prob_win
      # @team2's probabilities should not have changed (only @team was recalculated)
      assert_equal original_prob, @league_team2.reload.home_prob_win

      assert_redirected_to admin_league_league_team_path(admin_league_id: @league.id, id: @league_team.id)
      assert_match(/recalculated/i, flash[:notice])
    end

    test "recalculate requires authentication" do
      post recalculate_admin_league_league_teams_path(admin_league_id: @league.id)

      assert_redirected_to new_user_session_path
    end
  end
end
