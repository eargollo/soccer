# frozen_string_literal: true

module Leagues
  module Seasons
    class MatchesController < ApplicationController
      def index # rubocop:disable Metrics/AbcSize
        @league = League.find(params[:league_id])
        @season = @league.seasons.find_by(id: params[:season_id])

        if @season.nil?
          flash[:error] = 'No season found' # rubocop:disable Rails/I18nLocaleTexts
          redirect_to(league_seasons_path(@league))
          return
        end

        all_matches = @season.matches.order(:date, :round)
        @rounds = @season.matches.select(:round).distinct.pluck(:round).compact.sort

        # Determine default round: next match or last round if all finished
        default_round = determine_default_round(all_matches)

        # Use round from params or default
        selected_round = params[:round].present? ? params[:round].to_i : default_round
        @current_round = selected_round if @rounds.include?(selected_round)

        # Filter matches by selected round
        @matches = if @current_round.present?
                     all_matches.where(round: @current_round)
                   else
                     all_matches
                   end
      end

      private

      def determine_default_round(matches)
        # Find the next match (not finished, date >= current time)
        next_match = matches.where.not(status: 'Match Finished')
                            .where(date: Time.current..)
                            .order(:date)
                            .first

        if next_match
          next_match.round
        else
          # All matches finished, return the last round
          matches.maximum(:round)
        end
      end
    end
  end
end
