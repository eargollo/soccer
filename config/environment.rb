# frozen_string_literal: true

# Load the Rails application.
require_relative "application"

# Helio host
Rails.application.config.hosts << "soccer.helioho.st"

# Initialize the Rails application.
Rails.application.initialize!
