# frozen_string_literal: true

class UpdateLeagueJob < ApplicationJob
  queue_as :default

  def perform(id) # rubocop:disable Metrics/AbcSize
    season = id.nil? ? Season.target_season : Season.find_by(id:)

    next_match_finish_time = season.matches.not_started.minimum(:date) + 100.minutes

    season.seed if next_match_finish_time < Time.zone.now

    next_match_finish_time = season.matches.not_started.minimum(:date) + 100.minutes
    if next_match_finish_time > Time.zone.now
      Rails.logger.info("Next match at #{next_match_finish_time}")
      UpdateLeagueJob.set(wait_until: next_match_finish_time).perform_later(season.id)
    else
      Rails.logger.info("Next match was at #{next_match_finish_time} refreshing in 5 minutes")
      UpdateLeagueJob.set(wait_until: 30.minutes.from_now).perform_later(season.id)
    end
  end
end
