# frozen_string_literal: true

class ProbabilityRecalculator
  def self.call(league:, team: nil, lambda: Rails.application.config.probability.lambda)
    new(league: league, team: team, lambda: lambda).call
  end

  def initialize(league:, lambda:, team: nil)
    @league = league
    @team = team
    @lambda = lambda
  end

  def call
    # Reset probabilities to baseline for all teams (or just the specified team)
    reset_to_baseline

    # Get matches in chronological order
    matches = matches_in_order

    # Process each match to update probabilities
    # If recalculating for a specific team, only update that team's probabilities
    matches.each do |match|
      ProbabilityUpdater.call(match: match, lambda: @lambda, team: @team)
    end
  end

  private

  def reset_to_baseline
    teams_to_reset = @team ? [@team] : @league.league_teams.map(&:team)

    teams_to_reset.each do |team|
      league_team = @league.league_teams.find_or_initialize_by(team: team)
      baseline = @league.baseline

      league_team.assign_attributes(
        home_prob_win: baseline[0],
        home_prob_draw: baseline[1],
        home_prob_loss: baseline[2],
        away_prob_win: baseline[2], # flipped: home_loss → away_win
        away_prob_draw: baseline[1],
        away_prob_loss: baseline[0] # flipped: home_win → away_loss
      )

      league_team.save!
    end
  end

  def matches_in_order
    matches = @league.matches.finished

    # If team is specified, only get matches involving that team
    if @team
      matches = matches.where(
        'team_home_id = ? OR team_away_id = ?',
        @team.id, @team.id
      )
    end

    # Order by date ascending (oldest first) to process chronologically
    matches.order(date: :asc)
  end
end
