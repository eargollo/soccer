# frozen_string_literal: true

class LeaguesController < ApplicationController
  def show
    @league = League.new
    if params[:id] == "seed"
      @league.seed
    elsif params[:id] == "matches"
      @league.update_matches
    else
      redirect_to root_path
      return
    end

    render json: { param: params[:id] }
  end
end
