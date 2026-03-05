# rubocop:disable Metrics/MethodLength
# frozen_string_literal: true

class UpdateLeagueJob < ApplicationJob
  queue_as :default

  RETRY_AFTER_API_FAILURE = 10.minutes

  def perform(id) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    @id = id
    @season = id.nil? ? Season.target_season : Season.find_by(id:)

    if @season.nil?
      Rails.logger.info("No target season to update")
      schedule_next_update(nil)
      return
    end

    next_match_time = @season.matches.scheduled.minimum(:date)

    if next_match_time.nil?
      schedule_next_update(nil) unless @season.matches.pending.count.none?

      return
    end

    begin
      @season.seed if Time.zone.now > expected_finish_time(next_match_time)
    rescue Clients::ApiFootball::RequestError => e
      if e.transient?
        Rails.logger.error(
          "UpdateLeagueJob failed during season seed (will retry in #{RETRY_AFTER_API_FAILURE / 60} min): " \
          "status_code=#{e.status_code.inspect} response_body=#{e.response_body.inspect}"
        )
        Honeybadger.notify(
          e,
          context: {
            job: "UpdateLeagueJob",
            season_id: @season.id,
            status_code: e.status_code,
            response_body: e.response_body
          }
        )
        UpdateLeagueJob.set(wait: RETRY_AFTER_API_FAILURE).perform_later(@id)
        return
      end
      raise
    end

    new_next_match_time = @season.matches.scheduled.minimum(:date)

    if new_next_match_time != next_match_time
      schedule_simulation
      LeagueStanding.refresh
    end

    schedule_next_update(new_next_match_time)
  end

  private

  def expected_finish_time(match_time)
    match_time + 120.minutes
  end

  def schedule_simulation
    simulation = @season.simulations.create(name: "Auto simulation #{Time.zone.now}", runs: 1_000_000)
    SimulateJob.perform_later(simulation)
  end

  def schedule_next_update(match_time)
    update_time = if match_time.nil?
                    1.day.from_now
                  elsif Time.zone.now > expected_finish_time(match_time)
                    20.minutes.from_now
                  else
                    expected_finish_time(match_time)
                  end

    Rails.logger.info("Next match at #{match_time} scheduling to #{update_time}")
    UpdateLeagueJob.set(wait_until: update_time).perform_later(@id)
  end
end

# rubocop:enable Metrics/MethodLength
