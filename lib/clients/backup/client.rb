# frozen_string_literal: true

module Clients
  module Backup
    class Client
      def initialize(file = nil, observer: nil)
        @file = file || Rails.root.join("lib/clients/backup/backup.rb").to_s
        @observer = observer
        @current_league = nil
        @current_season = nil
      end

      def load
        content = File.read(@file)
        instance_eval(content, @file)
      end

      private

      def team(name:, reference:, logo:)
        team = Team.find_or_initialize_by(reference: reference)
        team.update!(name: name, logo: logo)
      end

      def league(country:, flag:, logo:, name:, reference:, **_kwargs, &block) # rubocop:disable Metrics/ParameterLists
        league = League.find_or_initialize_by(reference: reference)
        league.update!(country: country, flag: flag, logo: logo, name: name)

        @current_league = league
        instance_eval(&block) if block
        @current_league = nil
      end

      def season(year:, active:, **_kwargs, &block)
        raise "No league context for season" if @current_league.nil?

        season = @current_league.seasons.find_or_initialize_by(year: year)
        season.update!(active: active)

        @observer.presence&.season_created(season)

        @current_season = season
        instance_eval(&block) if block
        @current_season = nil
      end

      def match(date:, round:, round_name:, team_home:, team_away:, status:, result:, home_goals: nil, away_goals: nil, # rubocop:disable Metrics/ParameterLists, Metrics/AbcSize
                reference: nil)
        raise "No season context for match" if @current_season.nil?

        home_team = Team.find_by!(name: team_home)
        away_team = Team.find_by!(name: team_away)

        match_date = Time.zone.iso8601(date)

        match = if reference.present?
                  @current_season.matches.find_or_initialize_by(reference: reference)
                else
                  @current_season.matches.find_or_initialize_by(
                    team_home: home_team,
                    team_away: away_team,
                    round: round
                  )
                end

        # For opened seasons, only create matches if they don't exist
        # For closed seasons, always update matches
        return if @current_season.active && match.persisted?

        match_attributes = {
          date: match_date,
          round: round,
          round_name: round_name,
          team_home: home_team,
          team_away: away_team,
          home_goals: home_goals,
          away_goals: away_goals,
          status: status,
          result: result
        }
        match_attributes[:reference] = reference if reference.present?

        match.update!(match_attributes)
      end
    end
  end
end
