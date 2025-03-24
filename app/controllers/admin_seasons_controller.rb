# frozen_string_literal: true

class AdminSeasonsController < AdminController
  def update # rubocop:disable Metrics/AbcSize
    Rails.logger.info("Updating season #{params[:id]}")
    if params[:type] == 'sync'
      Rails.logger.info("Syncing season #{params[:id]}")
      season = Season.find(params[:id])
      season.seed
    else
      Rails.logger.info("Scheduling async update for season #{params[:id]}")
      UpdateLeagueJob.perform_later(params[:id])
    end

    redirect_to admin_leagues_path
  end
end
