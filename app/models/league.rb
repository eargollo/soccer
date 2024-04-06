# frozen_string_literal: true

class League < ApplicationRecord
  has_many :seasons, dependent: :destroy

  def self.client = Clients::ApiFootball::Client.new(ENV.fetch('APIFOOTBALL_TOKEN'))

  def seed
    @league_id = ENV.fetch('LEAGUE_ID')
    @season_id = ENV.fetch('SEASON_ID')

    Rails.logger.info "Importing league #{@league_id} season #{@season_id}"
    matches = League.client.matches(league_id: @league_id, season: @season_id)

    Rails.logger.info "Matches: #{matches.size}"

    matches.each do |m|
      import_match(m)
    end
  end

  def update_matches # rubocop:disable Metrics/AbcSize
    cli = League.client
    # Get matches that have been played but don't have results updated
    matches = Match.pending.played
    Rails.logger.info "Retrieved #{matches.size} matches to update."
    matches.each do |match|
      Rails.logger.info "Updating #{match.team_home.name} x #{match.team_away.name} at #{match.date}"
      m = cli.match(match.reference)
      updated = match.update(
        status: m.status,
        date: m.date,
        home_goals: m.home_goals,
        away_goals: m.away_goals,
        result: m.result
      )

      if updated
        Rails.logger.info "Match #{match.team_home.name} x #{match.team_away.name} updated."
      else
        Rails.logger.info "Failed to update Match #{match.id}(#{match.team_home.name} x #{match.team_away.name}):\n\t#{e.errors.full_messages.join("\n")}" # rubocop:disable Layout/LineLength
      end
    end
    matches
  end

  private

  def import_match(match) # rubocop:disable Metrics/AbcSize
    raise "Match #{match[:reference]} has no home team." if match[:home_team].nil? || match[:home_team]["id"].nil?

    home_team = Team.create_with(
      name: match[:home_team]["name"],
      logo: match[:home_team]["logo"]
    ).find_or_create_by(reference: match[:home_team]["id"])

    away_team = Team.create_with(
      name: match[:away_team]["name"],
      logo: match[:away_team]["logo"]
    ).find_or_create_by(reference: match[:away_team]["id"])

    Match.where(reference: match[:reference]).first_or_create(reference: match[:reference]).update(
      date: match[:date],
      round: match[:round],
      round_name: match[:round_name],
      team_home: home_team,
      team_away: away_team,
      home_goals: match[:home_goals],
      away_goals: match[:away_goals],
      status: match[:status],
      result: match[:result]
    )
  end
end
