# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id         :bigint           not null, primary key
#  logo       :string
#  name       :string
#  reference  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Team < ApplicationRecord
  has_one_attached :logo_cache

  has_many :home_matches, class_name: 'Match', foreign_key: 'team_home_id', dependent: :restrict_with_exception,
                          inverse_of: :team_home
  has_many :away_matches, class_name: 'Match', foreign_key: 'team_away_id', dependent: :restrict_with_exception,
                          inverse_of: :team_away

  has_many :standings, dependent: :restrict_with_exception
  has_many :simulation_standings, dependent: :restrict_with_exception
  has_many :league_standings, dependent: :restrict_with_exception

  def wins(season: nil) # rubocop:disable Metrics/AbcSize
    return home_matches.won_home.count + away_matches.won_away.count if season.nil?

    home_matches.won_home.where(season:).count + away_matches.won_away.where(season:).count
  end

  def losses(season: nil) # rubocop:disable Metrics/AbcSize
    return home_matches.won_away.count + away_matches.won_home.count if season.nil?

    home_matches.won_away.where(season:).count + away_matches.won_home.where(season:).count unless season.nil?
  end

  def draws(season: nil) # rubocop:disable Metrics/AbcSize
    return home_matches.draw.count + away_matches.draw.count if season.nil?

    home_matches.draw.where(season:).count + away_matches.draw.where(season:).count unless season.nil?
  end

  def goals_pro(season: nil) # rubocop:disable Metrics/AbcSize
    return home_matches.finished.sum(:home_goals) + away_matches.finished.sum(:away_goals) if season.nil?

    home_matches.where(season:).finished.sum(:home_goals) + away_matches.where(season:).finished.sum(:away_goals)
  end

  def goals_against(season: nil) # rubocop:disable Metrics/AbcSize
    if season.nil?
      return home_matches.where(status: 'Match Finished').sum(:away_goals) +
             away_matches.where(status: 'Match Finished').sum(:home_goals)
    end

    home_matches.where(season:).finished.sum(:away_goals) + away_matches.where(season:).finished.sum(:home_goals)
  end

  def logo_uri
    if logo_cache_available?
      Rails.application.routes.url_helpers.rails_blob_url(logo_cache, only_path: true)
    else
      cache_logo_async
      logo
    end
  end

  private

  def cache_logo_async
    return if logo_cache_available? || logo.blank?

    # Only queue job if not already processing
    return if Rails.cache.exist?(cache_lock_key)

    logo_cache.purge if logo_cache.attached?
    Rails.cache.write(cache_lock_key, true, expires_in: 5.minutes)
    CacheLogoJob.perform_later(id)
  end

  def logo_cache_available?
    logo_cache.attached? && logo_cache.blob.service.exist?(logo_cache.blob.key)
  end

  def cache_lock_key
    "team:#{id}:logo_cache_lock"
  end
end
