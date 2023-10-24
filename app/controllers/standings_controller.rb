# frozen_string_literal: true

class StandingsController < ApplicationController
  def index
    @standings = Standing.order(points: :desc, wins: :desc)
  end
end
