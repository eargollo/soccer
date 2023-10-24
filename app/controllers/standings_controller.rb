# frozen_string_literal: true

class StandingsController < ApplicationController
  def index
    @standings = Standing.all.order(points: :desc, wins: :desc)
  end
end
