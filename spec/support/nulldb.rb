# Unit specs run against the nulldb adapter: ActiveRecord behaves normally —
# models validate, callbacks fire, to_sql builds real queries — but nothing is
# written and queries come back empty. Persistence is ActiveRecord's concern and
# is tested upstream, so specs exercising only our own logic don't need a
# database underneath them. Prefer `build`/`new` over `create`; a spec needing
# `create` to read a record back is usually a spec that should be asserting
# something else.
#
# Specs that genuinely depend on the database — integration specs issuing HTTP,
# and the handful asserting what was actually written — carry `db: true`:
#
#   RSpec.describe UserPresenter, db: true do    # whole file
#   describe "#drawer_memberships", db: true do  # one block
#   it "enforces uniqueness", db: true do        # one example
#
# Two modes:
#
#   NULLDB=1       Adapter selected once for the process; `db: true` specs are
#                  excluded via --tag and run in a second pass on real SQLite.
#                  This is the default for routine runs — one connection, no
#                  per-example cost.
#
#   NULLDB=switch  Diagnostic. Swaps the adapter per example according to the
#                  tag, so a single run covers both populations — use it to find
#                  which specs actually need the database (run it, and anything
#                  that fails untagged wants either `db: true` or a rewrite onto
#                  `build`). Each swap has to drop every model's memoised column
#                  info, or inserts fail on missing NOT NULL defaults, so it is
#                  substantially slower than either single-adapter pass. Fine for
#                  diagnosis, not for the commit path.
if ENV["NULLDB"]
  require "nulldb"

  module NullDbAdapter
    NULLDB_CONFIG = { adapter: "nulldb", schema: "db/schema.rb" }.freeze

    class << self
      attr_accessor :real_config

      def use_nulldb!
        switch_to(NULLDB_CONFIG) unless current == "nulldb"
      end

      def use_real_db!
        switch_to(real_config) if current == "nulldb"
      end

      def current
        ActiveRecord::Base.connection_db_config.adapter.to_s
      rescue ActiveRecord::ConnectionNotEstablished
        nil
      end

      private

      def switch_to(config)
        ActiveRecord::Base.establish_connection(config)
        # Column info (including NOT NULL defaults) is memoised per model, so it
        # must be dropped when the adapter underneath changes — otherwise a model
        # that first loaded its columns from nulldb's schema.rb keeps them
        # against the real connection and inserts blow up on missing defaults.
        ActiveRecord::Base.descendants.each(&:reset_column_information)
      end
    end
  end

  RSpec.configure do |config|
    config.before(:suite) do
      NullDbAdapter.real_config = ActiveRecord::Base.connection_db_config
      NullDbAdapter.use_nulldb!
    end

    if ENV["NULLDB"] == "switch"
      config.around(:each) do |example|
        needs_db = example.metadata[:db] ||
          %i[feature request].include?(example.metadata[:type])

        needs_db ? NullDbAdapter.use_real_db! : NullDbAdapter.use_nulldb!
        example.run
      ensure
        NullDbAdapter.use_real_db!
      end
    else
      # Single-adapter pass: a `db: true` spec reaching this process means the
      # tag filter was wrong. Fail loudly rather than silently asserting against
      # empty query results.
      config.before(:each) do |example|
        if example.metadata[:db]
          raise "Spec is tagged `db: true` but this process is on nulldb. " \
                "Drop NULLDB=1, or use NULLDB=switch to run both populations."
        end
      end
    end
  end
end
