# frozen_string_literal: true

class League
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :reference

  def self.client = SoccerAPI::SoccerDataAPI::Client.new

  def initialize
    @reference = 216
  end

  def seed # rubocop:disable Metrics/AbcSize
    league = League.client

    Rails.logger.info "Importing league '#{league.name}'(id=#{league.id})..."

    Rails.logger.info "Teams: #{league.teams.size}"
    teams = import_teams(league.teams)

    Rails.logger.info "Matches: #{league.matches.size}"
    import_matches(league.matches, teams)
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
  # def initialize(attributes = {})
  #   attributes.each do |name, value|
  #     send("#{name}=", value)
  #   end
  # end

  def persisted?
    false
  end

  private

  def import_teams(teams)
    list = {}
    teams.each do |t|
      team = import_team(t)
      list[team.reference] = team
    end
    list
  end

  def import_team(import)
    team = Team.find_by(reference: import.id)
    if team.nil?
      Rails.logger.info "Creating team #{import.name}..."
      team = Team.create(name: import.name, reference: import.id)
    end
    team
  end

  def import_matches(matches, teams) # rubocop:disable Metrics/AbcSize, cs/MethodLength
    matches.each do |m|
      match = Match.find_by(reference: m.id)

      if match.nil?
        Rails.logger.info "Importing #{m.home_team} x #{m.away_team} at #{m.date}..."
        Match.create(
          date: m.date,
          team_home: teams[m.home_team_id],
          team_away: teams[m.away_team_id],
          status: m.status,
          home_goals: m.home_goals,
          away_goals: m.away_goals,
          result: m.result,
          reference: m.id
        )
      else
        Rails.logger.info "Skipping. Match #{m.home_team} x #{m.away_team} at #{m.date} already exists."
      end
    end
  end
end
