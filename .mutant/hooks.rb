# frozen_string_literal: true

# Mutant hook: give each forked worker its own SQLite database file.
#
# Mutant forks N worker processes (default: Etc.nprocessors). Without this hook
# all workers share storage/test.sqlite3 and compete for write locks, causing
# SQLite3::BusyException. This hook runs inside each forked child and:
#   1. Copies the schema-loaded template database to a worker-specific file
#   2. Reconnects ActiveRecord to the copy
#
# The template database is prepared once by rails_helper.rb (maintain_test_schema!)
# before mutant forks workers, so each copy already has the correct schema.

hooks.register(:mutation_worker_process_start) do |index:|
  require "fileutils"

  template_db = ::Rails.root.join("storage/test.sqlite3")
  worker_db   = ::Rails.root.join("storage/test_worker_#{index}.sqlite3")

  # Copy the template so this worker has an isolated, schema-ready database
  ::FileUtils.cp(template_db.to_s, worker_db.to_s)

  # Reconnect ActiveRecord to the worker-specific database
  config = ::ActiveRecord::Base.connection_db_config.configuration_hash.dup
  config[:database] = worker_db.to_s
  ::ActiveRecord::Base.establish_connection(config)
end
