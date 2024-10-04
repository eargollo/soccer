# frozen_string_literal: true

class TeamsController < ApplicationController
  def index
    @standings = LeagueStanding.all.sort_by(&:rate)
  end
end
