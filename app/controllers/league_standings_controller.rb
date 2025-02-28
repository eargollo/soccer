# frozen_string_literal: true

class LeagueStandingsController < ApplicationController
  # before_action :authenticate_user!

  def index
    @leagues = League.all
  end

  def show
    @standings = LeagueStanding.where(league_id: params[:id])
  end
end
