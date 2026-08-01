require "rails_helper"

RSpec.describe ExportCleanupJob, type: :job do
  let(:user) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  def request_with_archive(created_at:)
    request = create(:game_export_request, user: user, game: game, created_at: created_at)
    request.archive.attach(io: StringIO.new("zip"), filename: "e.zip", content_type: "application/zip")
    request
  end

  describe "#perform" do
    it "destroys everything the expired scope selects" do
      doomed = build_stubbed(:game_export_request)
      allow(doomed).to receive(:destroy)
      job = described_class.new
      allow(job).to receive(:expired).and_return(double(find_each: nil).tap { |d|
        allow(d).to receive(:find_each) { |&blk| blk.call(doomed) }
      })

      job.perform

      expect(doomed).to have_received(:destroy)
    end

    it "selects requests at or before the retention cutoff" do
      Timecop.freeze do
        sql = unquoted_sql(described_class.new.send(:expired))

        expect(sql).to include("game_export_requests.created_at <=")
      end
    end

    it "retains a full week" do
      expect(described_class::RETENTION).to eq(7.days)
    end
  end
end
