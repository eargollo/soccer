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
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    config.autoload_paths += %W[#{config.root}/lib/clients/**/]
    config.eager_load_paths += %W[#{config.root}/lib/clients/**/]

    config.active_support.to_time_preserves_timezone = :zone

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

    # Configure Active Storage for local storage without using storage.yml
    config.active_storage.service = :local

    # Define the local storage service programmatically
    config.active_storage.service_configurations = {
      local: {
        service: "Disk",
        root: Rails.root.join("storage/active_storage")
      }
    }
  end
end
