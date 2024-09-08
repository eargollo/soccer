# frozen_string_literal: true

class UpdateLeagueJob < ApplicationJob
  queue_as :default

  def perform(id) # rubocop:disable Metrics/AbcSize
    season = id.nil? ? Season.target_season : Season.find_by(id:)

    next_match_time = season.matches.not_started.minimum(:date)

    season.seed if next_match_time.nil? || next_match_time + 100.minutes < Time.zone.now

    next_match_time = season.matches.not_started.minimum(:date)
    if !next_match_time.nil? && next_match_time + 100.minutes > Time.zone.now
      Rails.logger.info("Next match at #{next_match_time}")
      UpdateLeagueJob.set(wait_until: next_match_time + 100.minutes).perform_later(season.id)
    else
      Rails.logger.info("Next match was at #{next_match_time} refreshing in 20 minutes")
      UpdateLeagueJob.set(wait_until: 20.minutes.from_now).perform_later(season.id)
    end
  end
end
