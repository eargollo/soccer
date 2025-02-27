# frozen_string_literal: true

require "test_helper"
require Rails.root.join('lib/clients/dataset/loader').to_s

class LoadLeagueJobTest < ActiveJob::TestCase
  test "#find_team returns nil if team is not at lookup table" do
    assert_nil(Clients::Dataset::Loader.find_team("does_not_exist"))
  end
end
