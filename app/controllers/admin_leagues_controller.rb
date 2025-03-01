# frozen_string_literal: true

class AdminLeaguesController < ApplicationController
  def index
    @leagues = League.all
  end

  def new
    @league = League.new
  end

  def create
    redirect_to admin_leagues_path
  end
end
