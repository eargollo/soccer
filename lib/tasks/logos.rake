# frozen_string_literal: true

require 'open-uri'
require 'uri'

namespace :logos do # rubocop:disable Metrics/BlockLength
  desc "Download all team logos from API Football and store locally"
  task download_all: :environment do # rubocop:disable Metrics/BlockLength
    logo_dir = Rails.public_path.join('team_logos')
    # FileUtils.mkdir_p(logo_dir) unless Dir.exist?(logo_dir)

    teams = Team.all
    total = teams.count
    success_count = 0
    failure_count = 0
    skipped_count = 0

    puts "Starting download of #{total} team logos..."
    puts "Logo directory: #{logo_dir}"

    teams.find_each.with_index do |team, index| # rubocop:disable Metrics/BlockLength
      if team.logo.blank? || team.reference.nil?
        failure_count += 1
        puts "[#{index + 1}/#{total}] Failing team #{team.id} (#{team.name}): missing logo or reference"
        next
      end

      # Determine file extension from URL or default to .png
      file_extension = File.extname(URI.parse(team.logo).path)
      file_extension = '.png' if file_extension.empty?
      filename = "team_#{team.reference}#{file_extension}"
      file_path = logo_dir.join(filename)

      if File.exist?(file_path)
        skipped_count += 1
        puts "[#{index + 1}/#{total}] Skipping team #{team.id} (#{team.name}): file already exists (#{filename})"
        next
      end

      # Download the logo
      puts "[#{index + 1}/#{total}] Downloading logo for team #{team.id} (#{team.name})..."
      downloaded_file = URI.parse(team.logo).open(
        read_timeout: 10,
        'User-Agent' => 'Mozilla/5.0 (compatible; Soccer App)'
      )

      File.binwrite(file_path, downloaded_file.read)
      success_count += 1
      puts "[#{index + 1}/#{total}] ✓ Successfully downloaded #{filename}"
    rescue URI::InvalidURIError => e
      failure_count += 1
      puts "[#{index + 1}/#{total}] ✗ Failed to download logo for team #{team.id} " \
           "(#{team.name}): Invalid URL - #{e.message}"
    rescue OpenURI::HTTPError => e
      failure_count += 1
      puts "[#{index + 1}/#{total}] ✗ Failed to download logo for team #{team.id} " \
           "(#{team.name}): HTTP Error #{e.message}"
    rescue StandardError => e
      failure_count += 1
      puts "[#{index + 1}/#{total}] ✗ Failed to download logo for team #{team.id} " \
           "(#{team.name}): #{e.class} - #{e.message}"
    end

    puts "\n#{'=' * 60}"
    puts "Download Summary:"
    puts "  Total teams: #{total}"
    puts "  Successfully downloaded: #{success_count}"
    puts "  Failed: #{failure_count}"
    puts "  Skipped: #{skipped_count}"
    puts "=" * 60
  end

  desc "Update team logos to point to local assets"
  task :update_to_local, [:dry_run] => :environment do |_t, args| # rubocop:disable Metrics/BlockLength
    dry_run = %w[true dry_run].include?(args[:dry_run])
    logo_dir = Rails.public_path.join('team_logos')

    teams = Team.all
    total = teams.count
    updated_count = 0
    skipped_count = 0
    not_found_count = 0

    puts "Starting update of team logos to local paths..."
    puts "Logo directory: #{logo_dir}"
    puts "Mode: #{dry_run ? 'DRY RUN (no changes will be made)' : 'LIVE (will update database)'}"
    puts ""

    teams.find_each.with_index do |team, index| # rubocop:disable Metrics/BlockLength
      # Skip teams without reference
      if team.reference.nil?
        skipped_count += 1
        puts "[#{index + 1}/#{total}] Skipping team #{team.id} (#{team.name}): no reference"
        next
      end

      # Check for local file (try common extensions)
      local_file = nil
      %w[.png .jpg .jpeg .svg].each do |ext|
        filename = "team_#{team.reference}#{ext}"
        file_path = logo_dir.join(filename)
        if File.exist?(file_path)
          local_file = "/team_logos/#{filename}"
          break
        end
      end

      # If no local file found, skip
      unless local_file
        not_found_count += 1
        puts "[#{index + 1}/#{total}] Skipping team #{team.id} (#{team.name}): " \
             "local file not found"
        next
      end

      # Skip if already pointing to local path
      if team.logo == local_file
        skipped_count += 1
        puts "[#{index + 1}/#{total}] Skipping team #{team.id} (#{team.name}): " \
             "already using local path"
        next
      end

      # Update logo to local path
      old_logo = team.logo
      if dry_run
        puts "[#{index + 1}/#{total}] [DRY RUN] Would update team #{team.id} " \
             "(#{team.name}): #{old_logo} -> #{local_file}"
      else
        team.update!(logo: local_file)
        puts "[#{index + 1}/#{total}] ✓ Updated team #{team.id} (#{team.name}): " \
             "#{old_logo} -> #{local_file}"
      end
      updated_count += 1
    end

    puts "\n#{'=' * 60}"
    puts "Update Summary:"
    puts "  Total teams: #{total}"
    puts "  #{dry_run ? 'Would update' : 'Updated'}: #{updated_count}"
    puts "  Skipped: #{skipped_count}"
    puts "  Local file not found: #{not_found_count}"
    puts "=" * 60
  end
end
