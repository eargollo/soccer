# frozen_string_literal: true

# == Schema Information
#
# Table name: seasons
#
#  id         :bigint           not null, primary key
#  active     :boolean          default(FALSE), not null
#  year       :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  league_id  :bigint           not null
#
# Indexes
#
#  index_seasons_on_league_id  (league_id)
#
# Foreign Keys
#
#  fk_rails_...  (league_id => leagues.id)
#
class Season < ApplicationRecord
  belongs_to :league
  has_many :matches, dependent: :destroy
  has_many :standings, dependent: :destroy
  has_many :simulations, dependent: :destroy

  class MatchesToPlayError < StandardError
  end

  def self.target_season
    season = Season.where(active: true).order(:year).last
    return season unless season.nil?

    Season.order(year: :desc, updated_at: :desc).first
  end

  def self.apifootball_seed(league_id:, season_id:) # rubocop:disable Metrics/AbcSize
    client = Clients::ApiFootball::Client.new(Rails.application.credentials.api_football.token)

    Rails.logger.info "Importing league #{league_id} season #{season_id}"
    matches = client.matches(league_id:, season: season_id)

    season = season_from_match(matches.first)

    Rails.logger.info "Matches: #{matches.size}"
    matches.each do |m|
      season.import_match(m)
    end

    season.close if season.all_matches_played?

    season
  end

  def self.season_from_match(match) # rubocop:disable Metrics/AbcSize
    league = League.find_or_create_by(reference: match[:league]["id"]) do |l|
      l.name = match[:league]["name"]
      l.country = match[:league]["country"]
      l.logo = match[:league]["logo"]
      l.flag = match[:league]["flag"]
    end

    league.seasons.find_or_create_by(year: match[:league]["season"])
  end

  def last_simulation
    simulations.where.not(finish: nil).last
  end

  def seed
    Rails.logger.info('Seeding season')
    Season.apifootball_seed(league_id: league.reference, season_id: year)
  end

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

    matches.where(reference: match[:reference]).first_or_create(reference: match[:reference]).update(
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

  def compute_standings
    Rails.logger.info('Computing standings')
    matches.each do |match|
      match.send(:compute_points_commit)
    end
  end

  def all_matches_played?
    matches.count == matches.where(status: ["Match Finished", "Match Cancelled"]).count
  end

  def update_standings_positions
    standings.select("*, goals_pro - goals_against as goals_difference")
             .order(points: :desc,
                    wins: :desc,
                    goals_difference: :desc,
                    goals_pro: :desc).each_with_index do |st, index|
      st.update!(position: index + 1)
    end
  end

  def close
    raise MatchesToPlayError unless all_matches_played?

    update_standings_positions
    update!(active: false)
  end
end
