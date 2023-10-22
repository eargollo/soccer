class StandingsController < ApplicationController
  def index
    @standings = Standing.all.order(points: :desc)
  end
end
