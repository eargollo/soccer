# frozen_string_literal: true

require "test_helper"

class TeamTest < ActiveSupport::TestCase
  def setup
    @team = teams(:barcelona)
    @league = leagues(:a_league)
    @other_league = League.create!(name: "Other League", reference: 999)
  end

  test "has many league_teams" do
    # Create LeagueTeam records for this team in different leagues
    league_team1 = LeagueTeam.create!(
      league: @league,
      team: @team,
      home_prob_win: 0.5.to_d,
      home_prob_draw: 0.3.to_d,
      home_prob_loss: 0.2.to_d,
      away_prob_win: 0.4.to_d,
      away_prob_draw: 0.3.to_d,
      away_prob_loss: 0.3.to_d
    )
    league_team2 = LeagueTeam.create!(
      league: @other_league,
      team: @team,
      home_prob_win: 0.6.to_d,
      home_prob_draw: 0.2.to_d,
      home_prob_loss: 0.2.to_d,
      away_prob_win: 0.3.to_d,
      away_prob_draw: 0.3.to_d,
      away_prob_loss: 0.4.to_d
    )

    assert_includes @team.league_teams, league_team1
    assert_includes @team.league_teams, league_team2
    assert_equal 2, @team.league_teams.count
  end

  test "destroying team destroys associated league_teams" do
    league_team = LeagueTeam.create!(
      league: @league,
      team: @team,
      home_prob_win: 0.5.to_d,
      home_prob_draw: 0.3.to_d,
      home_prob_loss: 0.2.to_d,
      away_prob_win: 0.4.to_d,
      away_prob_draw: 0.3.to_d,
      away_prob_loss: 0.3.to_d
    )

    @team.id
    @team.destroy

    assert_nil LeagueTeam.find_by(id: league_team.id)
  end
end
