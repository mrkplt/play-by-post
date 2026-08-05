require "rails_helper"

RSpec.describe GamePurgeSweepJob, type: :job do
  describe "#perform" do
    it "enqueues a purge job for every game the purgeable scope selects" do
      doomed = build_stubbed(:game)
      job = described_class.new
      relation = double
      allow(relation).to receive(:find_each) { |&blk| blk.call(doomed) }
      allow(job).to receive(:purgeable).and_return(relation)

      allow(GamePurgeJob).to receive(:perform_later)

      job.perform

      expect(GamePurgeJob).to have_received(:perform_later).with(doomed.id)
    end
  end

  describe "#purgeable" do
    it "selects games deleted at or before the retention cutoff" do
      Timecop.freeze do
        sql = unquoted_sql(described_class.new.purgeable)

        expect(sql).to include("games.deleted_at <=")
      end
    end

    it "ignores the default scope so soft-deleted games are visible" do
      # The default scope hides deleted games (deleted_at IS NULL); the sweep must
      # look past it, so the query must not carry that condition.
      expect(unquoted_sql(described_class.new.purgeable)).not_to include("deleted_at IS NULL")
    end

    context "at the retention boundary", db: true do
      it "includes a game deleted exactly at the cutoff and excludes one a second newer" do
        Timecop.freeze do
          on_boundary = create(:game, deleted_at: described_class::RETENTION.ago)
          just_inside = create(:game, deleted_at: described_class::RETENTION.ago + 1.second)

          ids = described_class.new.purgeable.pluck(:id)

          expect(ids).to include(on_boundary.id)
          expect(ids).not_to include(just_inside.id)
        end
      end

      it "excludes a live game" do
        live = create(:game)

        expect(described_class.new.purgeable.pluck(:id)).not_to include(live.id)
      end
    end
  end

  it "retains a full week" do
    expect(described_class::RETENTION).to eq(7.days)
  end
end
