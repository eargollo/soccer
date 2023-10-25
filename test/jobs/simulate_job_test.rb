require 'test_helper'

class SimulateJobTest < ActiveJob::TestCase
  test 'should enqueue job' do
    Match.create(date: DateTime.now, team_home: Team.first, team_away: Team.last, status: 'pending')
    SimulateJob.perform_later(runs: 10_000)
    assert_enqueued_with(job: SimulateJob)
    perform_enqueued_jobs
    assert_performed_jobs 1
  end
end
