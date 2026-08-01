# Unit specs can run against the nulldb adapter: ActiveRecord behaves normally
# — models validate, callbacks fire, to_sql builds real queries — but nothing is
# written and queries come back empty. Persistence is ActiveRecord's concern and
# is tested upstream, so specs exercising only our own logic don't need a
# database underneath them.
#
# Specs that DO depend on what the database actually did — uniqueness/FK
# constraints, callbacks that re-read, aggregate ordering, reading a record back
# after writing it — are marked `db: true`:
#
#   RSpec.describe UserPresenter, db: true do    # whole file
#   describe "#drawer_memberships", db: true do  # one block
#   it "enforces uniqueness", db: true do        # one example
#
# The adapter is chosen ONCE per process, via NULLDB=1, and the two populations
# are run as separate passes (see bin/pre-push). Switching per example was tried
# and is unusable: every switch has to drop each model's memoised column info,
# which took the unit tier from 6s to over two minutes.
if ENV["NULLDB"]
  require "nulldb"

  RSpec.configure do |config|
    config.before(:suite) do
      ActiveRecord::Base.establish_connection(adapter: "nulldb", schema: "db/schema.rb")
    end

    # Belt and braces: if a `db: true` spec is reached in a nulldb pass (a stray
    # tag filter, a focused run), fail loudly rather than silently asserting
    # against empty query results.
    config.before(:each) do |example|
      if example.metadata[:db]
        raise "Spec is tagged `db: true` but the process is running on nulldb. " \
              "Run it without NULLDB=1 (bin/pre-push runs both passes)."
      end
    end
  end
end
