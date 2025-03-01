# frozen_string_literal: true

class AdminLeaguesController < ApplicationController
  before_action :authenticate_user!

  def index
    @leagues = League.all
  end

  def show
    @league = League.find(params[:id])
    @seasons = @league.seasons
  end

  def new
    @league = League.new
  end

  def create
    redirect_to admin_leagues_path
  end
end
