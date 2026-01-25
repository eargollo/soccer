# frozen_string_literal: true

namespace :probabilities do # rubocop:disable Metrics/BlockLength
  desc "Initialize LeagueTeam records for all existing league-team combinations"
  task initialize: :environment do # rubocop:disable Metrics/BlockLength
    puts "Initializing LeagueTeam records for all league-team combinations..."

    # Find all unique league-team combinations from matches
    # Get home teams
    home_combinations = Match.joins(:season)
                             .distinct
                             .pluck('seasons.league_id, matches.team_home_id')

    # Get away teams
    away_combinations = Match.joins(:season)
                             .distinct
                             .pluck('seasons.league_id, matches.team_away_id')

    # Combine and get unique combinations
    combinations = (home_combinations + away_combinations).uniq

    total = combinations.count
    puts "Found #{total} unique league-team combinations"

    initialized = 0
    skipped = 0
    errors = 0

    combinations.each_with_index do |(league_id, team_id), index|
      league = League.find(league_id)
      team = Team.find(team_id)

      begin
        was_new = league.league_teams.find_by(team: team).nil?
        TeamProbabilityInitializer.call(league: league, team: team)
        if was_new
          initialized += 1
          puts "  [#{index + 1}/#{total}] Initialized: #{league.name} - #{team.name}"
        else
          skipped += 1
          puts "  [#{index + 1}/#{total}] Already exists: #{league.name} - #{team.name}"
        end
      rescue StandardError => e
        errors += 1
        puts "  [#{index + 1}/#{total}] ERROR: #{league.name} - #{team.name}: #{e.message}"
      end
    end

    puts "\nSummary:"
    puts "  Initialized: #{initialized}"
    puts "  Already existed: #{skipped}"
    puts "  Errors: #{errors}"
    puts "  Total: #{total}"
  end

  desc "Process historical matches to update team probabilities using EMA"
  task process_historical: :environment do # rubocop:disable Metrics/BlockLength
    league_id = ENV.fetch('LEAGUE_ID', nil)
    start_date = ENV.fetch('START_DATE', nil)
    start_match_id = ENV.fetch('START_MATCH_ID', nil)
    batch_size = (ENV['BATCH_SIZE'] || '100').to_i

    puts "Processing historical matches to update team probabilities..."
    puts "  League ID: #{league_id || 'all leagues'}"
    puts "  Start date: #{start_date || 'beginning'}"
    puts "  Start match ID: #{start_match_id || 'none'}"
    puts "  Batch size: #{batch_size}"

    # Build query for finished matches
    matches = Match.joins(:season).where(status: 'Match Finished')

    # Filter by league if specified
    if league_id.present?
      matches = matches.where(seasons: { league_id: league_id.to_i })
      league = League.find(league_id)
      puts "  Processing matches for: #{league.name}"
    end

    # Filter by start date if specified
    matches = matches.where(matches: { date: Date.parse(start_date).. }) if start_date.present?

    # Filter by start match ID if specified (for resuming)
    matches = matches.where('matches.id > ?', start_match_id.to_i) if start_match_id.present?

    # Order chronologically
    matches = matches.order('matches.date ASC, matches.id ASC')

    total = matches.count
    puts "  Total matches to process: #{total}"

    if total.zero?
      puts "No matches found to process."
      next
    end

    processed = 0
    errors = 0
    last_match_id = nil

    matches.find_in_batches(batch_size: batch_size) do |batch|
      batch.each do |match|
        # Ensure LeagueTeam records exist
        if match.team_home.present? && match.team_away.present? && match.league.present?
          TeamProbabilityInitializer.call(league: match.league, team: match.team_home)
          TeamProbabilityInitializer.call(league: match.league, team: match.team_away)
        end

        # Update probabilities using EMA
        ProbabilityUpdater.call(match: match)

        processed += 1
        last_match_id = match.id

        if (processed % 100).zero?
          puts "  Processed #{processed}/#{total} matches (last: match ##{last_match_id}, date: #{match.date})"
        end
      rescue StandardError => e
        errors += 1
        puts "  ERROR processing match ##{match.id} (#{match.team_home&.name} vs #{match.team_away&.name}): " \
             "#{e.message}"
        puts "    #{e.backtrace.first}" if e.backtrace
      end
    end

    puts "\nSummary:"
    puts "  Processed: #{processed}"
    puts "  Errors: #{errors}"
    puts "  Total: #{total}"
    puts "  Last match ID: #{last_match_id}" if last_match_id
    puts "\nTo resume from where you left off, run:"
    if last_match_id
      puts "  LEAGUE_ID=#{league_id} START_MATCH_ID=#{last_match_id} rake probabilities:process_historical"
    end
  end
end
