# frozen_string_literal: true

# == Schema Information
#
# Table name: league_teams
#
#  id              :bigint           not null, primary key
#  away_prob_draw  :decimal(5, 4)   default(0.0)
#  away_prob_loss  :decimal(5, 4)   default(0.0)
#  away_prob_win   :decimal(5, 4)   default(0.0)
#  home_prob_draw  :decimal(5, 4)   default(0.0)
#  home_prob_loss  :decimal(5, 4)   default(0.0)
#  home_prob_win   :decimal(5, 4)   default(0.0)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  league_id       :bigint           not null
#  team_id         :bigint           not null
#
# Indexes
#
#  index_league_teams_on_league_id_and_team_id  (league_id, team_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (league_id => leagues.id)
#  fk_rails_...  (team_id => teams.id)
#
require "test_helper"

class LeagueTeamTest < ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
  def setup
    @league = leagues(:a_league)
    @team = teams(:barcelona)
  end

  # Associations
  test "belongs to league" do
    league_team = LeagueTeam.new(league: @league, team: @team)
    assert_equal @league, league_team.league
  end

  test "belongs to team" do
    league_team = LeagueTeam.new(league: @league, team: @team)
    assert_equal @team, league_team.team
  end

  test "requires league" do
    league_team = LeagueTeam.new(team: @team)
    assert_not league_team.valid?
    assert_includes league_team.errors[:league], "must exist"
  end

  test "requires team" do
    league_team = LeagueTeam.new(league: @league)
    assert_not league_team.valid?
    assert_includes league_team.errors[:team], "must exist"
  end

  test "enforces unique league-team combination" do
    LeagueTeam.create!(
      league: @league,
      team: @team,
      home_prob_win: BigDecimal('0.5'),
      home_prob_draw: BigDecimal('0.3'),
      home_prob_loss: BigDecimal('0.2'),
      away_prob_win: BigDecimal('0.4'),
      away_prob_draw: BigDecimal('0.3'),
      away_prob_loss: BigDecimal('0.3')
    )
    duplicate = LeagueTeam.new(league: @league, team: @team)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:league_id], "has already been taken"
  end

  # Validations - Home Probabilities
  test "home probabilities must sum to 1.0" do
    league_team = LeagueTeam.new(
      league: @league,
      team: @team,
      home_prob_win: BigDecimal('0.5'),
      home_prob_draw: BigDecimal('0.3'),
      home_prob_loss: BigDecimal('0.2'),
      away_prob_win: BigDecimal('0.4'),
      away_prob_draw: BigDecimal('0.3'),
      away_prob_loss: BigDecimal('0.3')
    )
    assert league_team.valid?, league_team.errors.full_messages.join(', ')
  end

  test "home probabilities that do not sum to 1.0 are invalid" do
    league_team = LeagueTeam.new(
      league: @league,
      team: @team,
      home_prob_win: BigDecimal('0.5'),
      home_prob_draw: BigDecimal('0.3'),
      home_prob_loss: BigDecimal('0.1') # Sum = 0.9, not 1.0
    )
    assert_not league_team.valid?
    assert_includes league_team.errors[:home_probabilities], "must sum to 1.0"
  end

  test "home probabilities must be between 0 and 1" do
    league_team = LeagueTeam.new(
      league: @league,
      team: @team,
      home_prob_win: BigDecimal('-0.1'),
      home_prob_draw: BigDecimal('0.3'),
      home_prob_loss: BigDecimal('0.8')
    )
    assert_not league_team.valid?
    assert_includes league_team.errors[:home_prob_win], "must be between 0 and 1"
  end

  test "home probabilities cannot exceed 1.0" do
    league_team = LeagueTeam.new(
      league: @league,
      team: @team,
      home_prob_win: BigDecimal('1.1'),
      home_prob_draw: BigDecimal('0.0'),
      home_prob_loss: BigDecimal('0.0')
    )
    assert_not league_team.valid?
    assert_includes league_team.errors[:home_prob_win], "must be between 0 and 1"
  end

  # Validations - Away Probabilities
  test "away probabilities must sum to 1.0" do
    league_team = LeagueTeam.new(
      league: @league,
      team: @team,
      home_prob_win: BigDecimal('0.5'),
      home_prob_draw: BigDecimal('0.3'),
      home_prob_loss: BigDecimal('0.2'),
      away_prob_win: BigDecimal('0.4'),
      away_prob_draw: BigDecimal('0.3'),
      away_prob_loss: BigDecimal('0.3')
    )
    assert league_team.valid?
  end

  test "away probabilities that do not sum to 1.0 are invalid" do
    league_team = LeagueTeam.new(
      league: @league,
      team: @team,
      home_prob_win: BigDecimal('0.5'),
      home_prob_draw: BigDecimal('0.3'),
      home_prob_loss: BigDecimal('0.2'),
      away_prob_win: BigDecimal('0.4'),
      away_prob_draw: BigDecimal('0.3'),
      away_prob_loss: BigDecimal('0.2') # Sum = 0.9, not 1.0
    )
    assert_not league_team.valid?
    assert_includes league_team.errors[:away_probabilities], "must sum to 1.0"
  end

  test "away probabilities must be between 0 and 1" do
    league_team = LeagueTeam.new(
      league: @league,
      team: @team,
      home_prob_win: BigDecimal('0.5'),
      home_prob_draw: BigDecimal('0.3'),
      home_prob_loss: BigDecimal('0.2'),
      away_prob_win: BigDecimal('0.4'),
      away_prob_draw: BigDecimal('-0.1'),
      away_prob_loss: BigDecimal('0.7')
    )
    assert_not league_team.valid?
    assert_includes league_team.errors[:away_prob_draw], "must be between 0 and 1"
  end

  test "away probabilities cannot exceed 1.0" do
    league_team = LeagueTeam.new(
      league: @league,
      team: @team,
      home_prob_win: BigDecimal('0.5'),
      home_prob_draw: BigDecimal('0.3'),
      home_prob_loss: BigDecimal('0.2'),
      away_prob_win: BigDecimal('0.0'),
      away_prob_draw: BigDecimal('0.0'),
      away_prob_loss: BigDecimal('1.1')
    )
    assert_not league_team.valid?
    assert_includes league_team.errors[:away_prob_loss], "must be between 0 and 1"
  end

  # Edge cases
  test "allows probabilities at boundaries (0.0 and 1.0)" do
    league_team = LeagueTeam.new(
      league: @league,
      team: @team,
      home_prob_win: BigDecimal('1.0'),
      home_prob_draw: BigDecimal('0.0'),
      home_prob_loss: BigDecimal('0.0'),
      away_prob_win: BigDecimal('0.0'),
      away_prob_draw: BigDecimal('0.0'),
      away_prob_loss: BigDecimal('1.0')
    )
    assert league_team.valid?
  end

  test "handles very small probabilities" do
    league_team = LeagueTeam.new(
      league: @league,
      team: @team,
      home_prob_win: BigDecimal('0.0001'),
      home_prob_draw: BigDecimal('0.9998'),
      home_prob_loss: BigDecimal('0.0001'),
      away_prob_win: BigDecimal('0.0001'),
      away_prob_draw: BigDecimal('0.9998'),
      away_prob_loss: BigDecimal('0.0001')
    )
    assert league_team.valid?
  end

  test "handles precision correctly (4 decimal places)" do
    league_team = LeagueTeam.new(
      league: @league,
      team: @team,
      home_prob_win: BigDecimal('0.3333'),
      home_prob_draw: BigDecimal('0.3333'),
      home_prob_loss: BigDecimal('0.3334'), # Sum = 1.0
      away_prob_win: BigDecimal('0.3333'),
      away_prob_draw: BigDecimal('0.3333'),
      away_prob_loss: BigDecimal('0.3334')
    )
    assert league_team.valid?
  end

  # Helper methods (to be implemented)
  test "home_probabilities returns array of home probabilities" do
    league_team = LeagueTeam.new(
      league: @league,
      team: @team,
      home_prob_win: BigDecimal('0.5'),
      home_prob_draw: BigDecimal('0.3'),
      home_prob_loss: BigDecimal('0.2')
    )
    result = league_team.home_probabilities
    assert_equal 3, result.length
    assert_equal BigDecimal('0.5'), result[0]
    assert_equal BigDecimal('0.3'), result[1]
    assert_equal BigDecimal('0.2'), result[2]
  end

  test "away_probabilities returns array of away probabilities" do
    league_team = LeagueTeam.new(
      league: @league,
      team: @team,
      away_prob_win: BigDecimal('0.4'),
      away_prob_draw: BigDecimal('0.3'),
      away_prob_loss: BigDecimal('0.3')
    )
    result = league_team.away_probabilities
    assert_equal 3, result.length
    assert_equal BigDecimal('0.4'), result[0]
    assert_equal BigDecimal('0.3'), result[1]
    assert_equal BigDecimal('0.3'), result[2]
  end
end
