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
class LeagueTeam < ApplicationRecord
  belongs_to :league
  belongs_to :team

  # Uniqueness validation for league-team combination
  validates :league_id, uniqueness: { scope: :team_id }

  # Validations for individual probability values (must be between 0 and 1)
  validates :home_prob_win, :home_prob_draw, :home_prob_loss,
            :away_prob_win, :away_prob_draw, :away_prob_loss,
            presence: true,
            numericality: {
              greater_than_or_equal_to: 0.0,
              less_than_or_equal_to: 1.0,
              message: "must be between 0 and 1" # rubocop:disable Rails/I18nLocaleTexts
            }

  validate :home_probabilities_sum_to_one
  validate :away_probabilities_sum_to_one

  def home_probabilities
    [home_prob_win, home_prob_draw, home_prob_loss]
  end

  def away_probabilities
    [away_prob_win, away_prob_draw, away_prob_loss]
  end

  private

  def home_probabilities_sum_to_one
    return if home_prob_win.nil? || home_prob_draw.nil? || home_prob_loss.nil?

    sum = home_prob_win + home_prob_draw + home_prob_loss
    return if sum == 1

    errors.add(:home_probabilities, "must sum to 1.0")
  end

  def away_probabilities_sum_to_one
    return if away_prob_win.nil? || away_prob_draw.nil? || away_prob_loss.nil?

    sum = away_prob_win + away_prob_draw + away_prob_loss
    return if sum == 1

    errors.add(:away_probabilities, "must sum to 1.0")
  end
end
