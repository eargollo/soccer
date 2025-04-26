# frozen_string_literal: true

require 'open-uri'

class CacheLogoJob < ApplicationJob
  queue_as :default

  def perform(team_id)
    team = Team.find(team_id)
    return if team.logo.blank? || team.logo_cache.attached?

    begin
      downloaded_file = URI.parse(team.logo).open
      team.logo_cache.attach(
        io: downloaded_file,
        filename: "team_#{team.id}_logo#{File.extname(team.logo)}",
        content_type: downloaded_file.content_type
      )
    ensure
      Rails.cache.delete("team:#{team_id}:logo_cache_lock")
    end
  end
end
