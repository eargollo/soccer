# frozen_string_literal: true

# == Schema Information
#
# Table name: leagues
#
#  id         :bigint           not null, primary key
#  country    :string
#  flag       :string
#  logo       :string
#  name       :string           not null
#  reference  :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class League < ApplicationRecord
  has_many :seasons, dependent: :destroy
  has_many :league_standings, dependent: :destroy
  has_many :matches, through: :seasons

  def target_season
    seasons.where(active: true).order(year: :desc).first ||
      seasons.order(year: :desc).first
  end

  def probability # rubocop:disable Metrics/AbcSize
    return @probability unless @probability.nil?
    return [0.45, 0.30, 0.25] if matches.finished.count < 500

    home_wins = matches.won_home.count
    home_draws = matches.draw.count
    home_losses = matches.won_away.count
    total = home_wins + home_draws + home_losses

    @probability = [
      home_wins.to_f / total,
      home_draws.to_f / total,
      home_losses.to_f / total
    ]
  end

  def team_home_probability(team:, limit: nil, minimum: nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    minimum ||= 80
    limit ||= 100_000

    @team_home_probability ||= {}
    @team_home_probability[{ minimum:, limit: }] ||= {}

    return @team_home_probability[minimum:, limit:][team] if @team_home_probability[minimum:, limit:][team]
    return probability if matches.where(team_home: team).where.not(result: "tbd").count < minimum

    query = "SELECT result, COUNT(*) as total
               FROM (
                SELECT result
                  FROM matches, seasons
                  WHERE seasons.id = matches.season_id AND
                       seasons.league_id = ? AND
                       team_home_id = ? AND
                       result != 'tbd'
                  ORDER BY date DESC LIMIT ? )
               GROUP BY result"

    sq = ApplicationRecord.sanitize_sql_for_conditions([query, id, team.id, limit])
    result = ActiveRecord::Base.connection.execute(sq)

    probs = [0, 0, 0]
    result.each do |r|
      if r['result'] == 'home'
        probs[0] = r['total']
      elsif r['result'] == 'draw'
        probs[1] = r['total']
      else
        probs[2] = r['total']
      end
    end

    total = probs.sum

    @team_home_probability[minimum:, limit:][team] = [
      probs[0].to_f / total,
      probs[1].to_f / total,
      probs[2].to_f / total
    ]
  end

  def team_away_probability(team:, limit: nil, minimum: nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    minimum ||= 80
    limit ||= 100_000

    @team_away_probability ||= {}
    @team_away_probability[{ minimum:, limit: }] ||= {}

    return @team_away_probability[minimum:, limit:][team] if @team_away_probability[minimum:, limit:][team]
    return probability if matches.where(team_away: team).where.not(result: "tbd").count < minimum

    query = "SELECT result, COUNT(*) as total
               FROM (
                SELECT result
                  FROM matches, seasons
                  WHERE seasons.id = matches.season_id AND
                       seasons.league_id = ? AND
                       team_away_id = ? AND
                       result != 'tbd'
                  ORDER BY date DESC LIMIT ? )
               GROUP BY result"

    sq = ApplicationRecord.sanitize_sql_for_conditions([query, id, team.id, limit])
    result = ActiveRecord::Base.connection.execute(sq)

    probs = [0, 0, 0]
    result.each do |r|
      if r['result'] == 'home'
        probs[0] = r['total']
      elsif r['result'] == 'draw'
        probs[1] = r['total']
      else
        probs[2] = r['total']
      end
    end

    total = probs.sum

    @team_away_probability[minimum:, limit:][team] = [
      probs[0].to_f / total,
      probs[1].to_f / total,
      probs[2].to_f / total
    ]
  end
end
