# frozen_string_literal: true

class LeaguesController < ApplicationController
  def index
    @leagues = League.all
  end

  def show
    @league = League.find(params[:id])
    @seasons = @league.seasons.order(year: :asc)
  end
end
