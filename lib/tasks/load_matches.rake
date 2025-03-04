# frozen_string_literal: true

namespace :import do
  desc "Import entire league data"
  task league: :environment do
    loader = Clients::Dataset::Loader.new
    missing = loader.teams_missing.sort
    unless missing.empty?
      puts "Can't import league data. There are #{missing.length} missing teams:"
      puts "'#{missing.join("', '")}'"
    end
  end
end
