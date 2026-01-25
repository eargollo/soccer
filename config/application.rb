# frozen_string_literal: true

require_relative "boot"

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Soccer
  class Application < Rails::Application
    # Use application authentication to access `/jobs` interface
    MissionControl::Jobs.base_controller_class = "AdminController"
    config.mission_control.jobs.http_basic_auth_enabled = false

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    config.autoload_paths += %W[#{config.root}/lib/clients/**/]
    config.eager_load_paths += %W[#{config.root}/lib/clients/**/]

    # Job interface
    config.active_job.queue_adapter = :solid_queue
    # config.active_job.queue_adapter = ActiveJob::QueueAdapters::AsyncAdapter.new(
    #   min_threads: 1,
    #   max_threads: 2 * Concurrent.processor_count,
    #   idletime: 600.seconds
    # )

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Probability calculation configuration
    # Exponential Moving Average (EMA) decay factor
    # Higher lambda = more responsive to recent results, less weight on history
    # Default: 0.15 (15%)
    config.probability = ActiveSupport::OrderedOptions.new
    config.probability.lambda = ENV.fetch('PROBABILITY_LAMBDA', '0.15').to_d

    # Probability combination weights
    # How much to weight home team's home probability vs away team's away probability
    # Default: 60% home, 40% away
    # away_weight is derived from home_weight to ensure they always sum to 1.0
    config.probability.combiner_home_weight = ENV.fetch('PROBABILITY_COMBINER_HOME_WEIGHT', '0.6').to_d
    config.probability.combiner_away_weight = 1.to_d - config.probability.combiner_home_weight

    # Feature flag: Use new EMA-based probability calculation
    # When true: Uses MatchProbabilityCalculator with EMA model
    # When false: Uses legacy probability calculation
    # Default: false (use legacy)
    config.probability.use_ema_calculation = ENV.fetch('USE_EMA_PROBABILITY', 'false') == 'true'
  end
end
