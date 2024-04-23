# frozen_string_literal: true

namespace :import do
  desc "Import entire league data"
  task league: :environment do
    target = Season.target_season
    if target.nil?
      Season.apifootball_seed(league_id: 71, season_id: 2024)
      return
    end

    target.seed
  end
end
