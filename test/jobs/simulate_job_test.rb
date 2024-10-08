# frozen_string_literal: true

require "test_helper"

class SimulateJobTest < ActiveJob::TestCase
  setup do
    @original_queue_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
  end

  teardown do
    ActiveJob::Base.queue_adapter = @original_queue_adapter
  end
  test 'should enqueue job' do
    season = seasons(:season1)
    season.matches.create(date: DateTime.now, team_home: Team.first, team_away: Team.last, status: 'Not Started')
    season.simulations.create(runs: 1000)
    assert_enqueued_with(job: SimulateJob)
    perform_enqueued_jobs
    assert_performed_jobs 1
  end
end
