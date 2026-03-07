# frozen_string_literal: true

module Leagues
  class PositionRankingsController < ApplicationController
    DEFAULT_POSITIONS = 20

    def show
      @league = League.find(params[:id])
      positions = (params[:positions].presence&.to_i || DEFAULT_POSITIONS).clamp(1, 20)
      @positions_range = 1..positions
      @ranking = LeaguePositionCount.for_league(@league.id, positions: @positions_range)
    end
  end
end
