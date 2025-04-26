# frozen_string_literal: true

# == Schema Information
#
# Table name: seasons
#
#  id         :bigint           not null, primary key
#  active     :boolean          default(FALSE), not null
#  year       :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  league_id  :bigint           not null
#
# Indexes
#
#  index_seasons_on_league_id  (league_id)
#
# Foreign Keys
#
#  fk_rails_...  (league_id => leagues.id)
#
require "test_helper"

class SeasonTest < ActiveSupport::TestCase
  def setup
    @season = seasons(:season1)
    @bcn = teams(:barcelona)
    @rmd = teams(:madrid)

    @season.matches.create(team_home: @bcn, team_away: @rmd, home_goals: 2, away_goals: 1, status: 'Match Finished')
    @season.matches.create(team_home: @rmd, team_away: @bcn)
  end

  test "#close raises if not all matches are played" do
    assert_raises Season::MatchesToPlayError do
      @season.close
    end
  end

  test "#close makes inactive if all matches are played" do
    @season.matches.last.update!(home_goals: 3, away_goals: 0, status: 'Match Finished')
    @season.close

    assert_equal(false, @season.active)
  end

  test "#close updates positions" do
    @season.matches.last.update!(home_goals: 3, away_goals: 0, status: 'Match Finished')
    @season.close

    standings = @season.standings.order(:position)
    first = standings.first
    second = standings.second
    assert_equal(1, first.position)
    assert_equal(@rmd, first.team)
    assert_equal(2, second.position)
    assert_equal(@bcn, second.team)
  end

  test "#update_standings_positions updates position for ongoing season" do
    @season.update_standings_positions
    standings = @season.standings.order(:position)
    first = standings.first
    second = standings.second
    assert_equal(1, first.position)
    assert_equal(@bcn, first.team)
    assert_equal(2, second.position)
    assert_equal(@rmd, second.team)
  end
end
