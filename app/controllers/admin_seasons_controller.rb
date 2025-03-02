# frozen_string_literal: true

class AdminSeasonsController < ApplicationController
  before_action :authenticate_user!

  def update
    UpdateLeagueJob.perform_later(params[:id])

    render status: :ok
  end
end
