# frozen_string_literal: true

# Ignore backup.rb from Zeitwerk autoloading
# This file is a DSL/data file, not a Ruby class
Rails.autoloaders.main.ignore(
  Rails.root.join("lib/clients/backup/backup.rb")
)
