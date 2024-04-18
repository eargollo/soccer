# frozen_string_literal: true

require "test_helper"

class MatchTest < ActiveSupport::TestCase
  # BASE * 1 + LEAGUE * 19 + TEAM_LAST_SEASON  * 20 + LAST_30 * 60
  FACTOR = 4.5
  def setup
    @bcn = teams(:barcelona)
    @mad = teams(:madrid)
    @esp = teams(:espanyol)

    @prev_season = leagues(:a_league).seasons.create(year: 2022)
    @season = seasons(:season1)
  end

  test "standard probability with no matches" do
    assert_equal([0.45, 0.30, 0.25], @season.matches.new.probability.map { |f| f.round(2) })
  end

  def round_array(array)
    array.map { |f| f.round(2) }
  end
end
