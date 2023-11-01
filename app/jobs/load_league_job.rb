require 'rake'

require_relative 'lib/tasks/import.rake'

class LoadLeagueJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rake::Task['import:league'].invoke
  end
end
