# frozen_string_literal: true

class AdminSeasonsController < AdminController
  def update
    Rails.logger.info("Updating season #{params[:id]}")
    UpdateLeagueJob.perform_later(params[:id])

    if Rails.env.development?
      season = Season.find(params[:id])
      season.seed
    end

    redirect_to admin_leagues_path
  end
end
