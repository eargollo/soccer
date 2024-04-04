# frozen_string_literal: true

class LeaguesController < ApplicationController
  before_action :authenticate_user!

  def show
    @league = League.new
    results = nil
    if params[:id] == "seed"
      @league.seed
    elsif params[:id] == "matches"
      results = @league.update_matches
    else
      redirect_to root_path
      return
    end

    render json: { param: params[:id], results: }
  end
end
