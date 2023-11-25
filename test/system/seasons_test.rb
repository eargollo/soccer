# frozen_string_literal: true

require "application_system_test_case"

class SeasonsTest < ApplicationSystemTestCase
  setup do
    @season = seasons(:one)
  end

  test "visiting the index" do
    visit seasons_url
    assert_selector "h1", text: "Seasons"
  end

  test "should create season" do
    visit seasons_url
    click_on "New season"

    fill_in "League", with: @season.league_id
    fill_in "Year", with: @season.year
    click_on "Create Season"

    assert_text "Season was successfully created"
    click_on "Back"
  end

  test "should update Season" do
    visit season_url(@season)
    click_on "Edit this season", match: :first

    fill_in "League", with: @season.league_id
    fill_in "Year", with: @season.year
    click_on "Update Season"

    assert_text "Season was successfully updated"
    click_on "Back"
  end

  test "should destroy Season" do
    visit season_url(@season)
    click_on "Destroy this season", match: :first

    assert_text "Season was successfully destroyed"
  end
end
