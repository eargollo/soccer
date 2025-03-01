# frozen_string_literal: true

class AdminLeaguesController < ApplicationController
  def index
    @leagues = League.all
  end
end
