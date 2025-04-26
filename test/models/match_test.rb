# frozen_string_literal: true

# == Schema Information
#
# Table name: matches
#
#  id           :bigint           not null, primary key
#  away_goals   :integer
#  date         :datetime
#  home_goals   :integer
#  reference    :integer
#  result       :string
#  round        :integer
#  round_name   :string
#  status       :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  season_id    :bigint           default(1), not null
#  team_away_id :bigint           not null
#  team_home_id :bigint           not null
#
# Indexes
#
#  index_matches_on_season_id     (season_id)
#  index_matches_on_team_away_id  (team_away_id)
#  index_matches_on_team_home_id  (team_home_id)
#
# Foreign Keys
#
#  fk_rails_...  (season_id => seasons.id)
#  fk_rails_...  (team_away_id => teams.id)
#  fk_rails_...  (team_home_id => teams.id)
#
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
