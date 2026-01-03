# frozen_string_literal: true

namespace :serieb do
  desc "Import matches from serie b apifootball dataset"
  task apifootball: :environment do
    require "vcr"
    require "uri"
    VCR.configure do |config|
      config.cassette_library_dir = "lib/clients/api_football/vcr/serieb"
      config.hook_into :webmock
      config.ignore_request do |request|
        URI(request.uri).host == "api.honeybadger.io"
      end
    end

    # Started with two rounds only in 2006
    seasons = (2012..2014).to_a + (2016..2025).to_a
    seasons.each do |year|
      puts year

      VCR.use_cassette("apifootball_#{year}", record_on_error: false) do |_cassette|
        Season.apifootball_seed(league_id: 72, season_id: year)
      end
    end
  end
end
