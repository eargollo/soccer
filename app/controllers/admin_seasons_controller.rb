# frozen_string_literal: true

class AdminSeasonsController < ApplicationController
  before_action :authenticate_user!

  def update
    Rails.logger.info("Updating season #{params[:id]}")
    UpdateLeagueJob.perform_later(params[:id])

    redirect_to admin_leagues_path
  end
end
