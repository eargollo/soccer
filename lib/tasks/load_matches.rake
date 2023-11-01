# frozen_string_literal: true

namespace :import do
  desc "Import entire league data"
  task league: :environment do
    league = League.new
    league.seed
  end

  desc "Import newly played matches"
  task matches: :environment do
    league = League.new
    league.update_matches
  end
end
