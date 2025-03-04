# frozen_string_literal: true

require "test_helper"
require Rails.root.join('lib/clients/dataset/loader').to_s

class LoadLeagueJobTest < ActiveJob::TestCase
  test ".find_team returns nil if team is not at lookup table" do
    assert_nil(Clients::Dataset::Loader.find_team("does_not_exist"))
  end

  test ".find_team returns team if team is at lookup table" do
    team = teams(:barcelona)
    ApiClientTeam.create!(client_id: Clients::Dataset::CLIENT_ID, client_key: "Barcelona Spain", team: team)
    assert_equal(team, Clients::Dataset::Loader.find_team("Barcelona Spain"))
  end

  test ".guess_team returns nil if no team has a similar name" do
    assert_nil(Clients::Dataset::Loader.guess_team("does_not_exist"))
  end

  test ".guess_team returns team if team has a similar name" do
    team = teams(:barcelona)
    assert_equal(team, Clients::Dataset::Loader.guess_team("Barcelona"))
  end

  test "#new loads all matches" do
    loader = Clients::Dataset::Loader.new
    assert_equal(8405, loader.matches.length)
    assert_equal("Guarani", loader.matches.first["mandante"])
  end

  test "#teams returns all teams" do
    loader = Clients::Dataset::Loader.new
    assert_equal(45, loader.teams.length)
    assert_equal("Guarani", loader.teams.first)
  end

  test "#teams_missing returns all teams that are not at teams table" do
    loader = Clients::Dataset::Loader.new(file_fixture("campeonato-brasileiro-missing.csv"))
    missing = loader.teams_missing.sort
    assert_equal(2, missing.length)
    assert_equal("Guarani", missing.first)
    assert_equal("Super Real Madrid", missing.second)
  end

  test "#teams_missing returns all teams that are also not in lookup" do
    ApiClientTeam.create!(client_id: Clients::Dataset::CLIENT_ID, client_key: "Super Real Madrid", team: teams(:madrid))

    loader = Clients::Dataset::Loader.new(file_fixture("campeonato-brasileiro-missing.csv"))
    missing = loader.teams_missing.sort
    assert_equal(1, missing.length)
    assert_equal("Guarani", missing.first)
  end
end
