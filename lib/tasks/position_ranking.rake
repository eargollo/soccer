# frozen_string_literal: true

namespace :position_ranking do
  desc "Backfill standings.position for all finished seasons, then refresh materialized views. " \
       "Run this if you have finished seasons (active=false) but position ranking is empty " \
       "because position was never set (e.g. seasons closed before this feature or imported)."
  task backfill: :environment do
    finished = Season.where(active: false)
    puts "Found #{finished.count} finished season(s)."

    finished.find_each do |season|
      season.update_standings_positions
      puts "  Updated positions for #{season.league.name} #{season.year}"
    end

    LeagueStanding.refresh
    puts "Refreshed materialized views (standings + position ranking)."
  end
end
