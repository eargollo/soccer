# frozen_string_literal: true

require "test_helper"

class AdminLeaguesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @league = leagues(:a_league)
  end

  test "show returns success when signed in" do
    sign_in @user
    get admin_league_path(@league)
    assert_response :success
    assert_match @league.name, response.body
  end

  test "show requires authentication" do
    get admin_league_path(@league)
    assert_redirected_to new_user_session_path
  end

  test "refresh_materialized_views refreshes and redirects with flash" do
    sign_in @user
    post refresh_materialized_views_admin_league_path(@league)
    assert_redirected_to admin_league_path(@league)
    assert_match(/refreshed/i, flash[:notice])
  end

  test "refresh_materialized_views requires authentication" do
    post refresh_materialized_views_admin_league_path(@league)
    assert_redirected_to new_user_session_path
  end
end
