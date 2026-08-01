require "rails_helper"

RSpec.describe ExportCleanupJob, type: :job, db: true do
  let(:user) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  def request_with_archive(created_at:)
    request = create(:game_export_request, user: user, game: game, created_at: created_at)
    request.archive.attach(io: StringIO.new("zip"), filename: "e.zip", content_type: "application/zip")
    request
  end

  describe "#perform" do
    it "destroys export requests older than the retention window" do
      old = create(:game_export_request, user: user, game: game, created_at: 8.days.ago)

      expect { ExportCleanupJob.new.perform }.to change(GameExportRequest, :count).by(-1)
      expect(GameExportRequest.exists?(old.id)).to be(false)
    end

    it "keeps export requests within the retention window" do
      recent = create(:game_export_request, user: user, game: game, created_at: 6.days.ago)

      expect { ExportCleanupJob.new.perform }.not_to change(GameExportRequest, :count)
      expect(GameExportRequest.exists?(recent.id)).to be(true)
    end

    it "keeps a request just inside the retention boundary" do
      Timecop.freeze do
        boundary = create(:game_export_request, user: user, game: game, created_at: 7.days.ago + 1.second)

        ExportCleanupJob.new.perform
        expect(GameExportRequest.exists?(boundary.id)).to be(true)
      end
    end

    it "deletes a request exactly at the retention cutoff (inclusive boundary)" do
      Timecop.freeze do
        at_cutoff = create(:game_export_request, user: user, game: game, created_at: 7.days.ago)

        ExportCleanupJob.new.perform
        expect(GameExportRequest.exists?(at_cutoff.id)).to be(false)
      end
    end

    it "purges the attached archive of an expired request" do
      old = request_with_archive(created_at: 8.days.ago)
      blob = old.archive.blob

      ExportCleanupJob.new.perform

      expect(ActiveStorage::Blob.exists?(blob.id)).to be(false)
    end

    it "handles expired requests that have no archive attached" do
      create(:game_export_request, user: user, game: game, created_at: 8.days.ago)

      expect { ExportCleanupJob.new.perform }.not_to raise_error
    end
  end
end
