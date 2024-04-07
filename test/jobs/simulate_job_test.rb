# frozen_string_literal: true

require "test_helper"

class SimulateJobTest < ActiveJob::TestCase
  test 'should enqueue job' do
    season = seasons(:season_23)
    season.matches.create(date: DateTime.now, team_home: Team.first, team_away: Team.last, status: 'pending')
    season.simulations.create(runs: 1000)
    assert_enqueued_with(job: SimulateJob)
    perform_enqueued_jobs
    assert_performed_jobs 1
  end
end
