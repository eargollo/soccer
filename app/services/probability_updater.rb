# frozen_string_literal: true

class ProbabilityUpdater
  def self.call(match:, lambda: Rails.application.config.probability.lambda, team: nil)
    new(match: match, lambda: lambda, team: team).call
  end

  def initialize(match:, lambda:, team: nil)
    @match = match
    @lambda = lambda
    @team = team
  end

  def call
    return unless @match.finished?

    league = @match.league
    return unless league

    # Update home team's home probability (only if @team is nil or matches home team)
    if @team.nil? || @team == @match.team_home
      update_team_probability(
        league: league,
        team: @match.team_home,
        context: :home,
        result: @match.result
      )
    end

    # Update away team's away probability (only if @team is nil or matches away team)
    return unless @team.nil? || @team == @match.team_away

    update_team_probability(
      league: league,
      team: @match.team_away,
      context: :away,
      result: @match.result
    )
  end

  private

  def update_team_probability(league:, team:, context:, result:) # rubocop:disable Metrics/AbcSize
    # TeamProbabilityInitializer handles find-or-create logic
    league_team = TeamProbabilityInitializer.call(league: league, team: team)

    # Get current probabilities based on context
    probabilities = if context == :home
                      [league_team.home_prob_win, league_team.home_prob_draw, league_team.home_prob_loss]
                    else
                      [league_team.away_prob_loss, league_team.away_prob_draw, league_team.away_prob_win]
                    end

    # Map match result to probability index (0=win, 1=draw, 2=loss) from team's perspective
    result_index = map_result_to_index(result: result)

    # Apply EMA formula: decay all, then add lambda to result
    probabilities.map! { |p| p * (1.to_d - @lambda) }
    probabilities[result_index] += @lambda

    # Round win and draw, derive loss to ensure exact sum = 1.0
    probabilities[0] = probabilities[0].round(4)
    probabilities[1] = probabilities[1].round(4)
    probabilities[2] = (1.to_d - probabilities[0] - probabilities[1]).round(4)

    # Assign to correct fields based on context
    if context == :home
      league_team.home_prob_win = probabilities[0]
      league_team.home_prob_draw = probabilities[1]
      league_team.home_prob_loss = probabilities[2]
    else
      league_team.away_prob_win = probabilities[2]
      league_team.away_prob_draw = probabilities[1]
      league_team.away_prob_loss = probabilities[0]
    end

    league_team.save!
  end

  def map_result_to_index(result:)
    # Returns index: 0=win, 1=draw, 2=loss
    case result
    when 'home' then 0  # home win
    when 'draw' then 1  # draw
    when 'away' then 2  # home loss
    else
      raise ArgumentError, "Invalid result: #{result}"
    end
  end
end
