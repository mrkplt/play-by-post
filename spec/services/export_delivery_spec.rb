require "rails_helper"

RSpec.describe ExportDelivery do
  let(:user) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
    ActiveJob::Base.queue_adapter = original_adapter
  end

  def request_with_archive
    request = create(:game_export_request, user: user, game: game, succeeded_at: 1.hour.ago)
    request.archive.attach(io: StringIO.new("zip"), filename: "e.zip", content_type: "application/zip")
    request
  end

  describe ".request!" do
    context "when a valid receipt already exists" do
      it "resends the existing receipt's download link instead of creating a new request" do
        existing = request_with_archive
        allow(GameExportRequest).to receive(:valid_receipt_for).with(user, game).and_return(existing)
        allow(described_class).to receive(:email_download_link)

        expect {
          described_class.request!(user: user, game: game)
        }.not_to change(GameExportRequest, :count)

        expect(described_class).to have_received(:email_download_link).with(existing)
      end
    end

    context "when no valid receipt exists" do
      it "creates a new export request and enqueues ExportJob" do
        allow(GameExportRequest).to receive(:valid_receipt_for).with(user, game).and_return(nil)

        expect {
          described_class.request!(user: user, game: game)
        }.to change(GameExportRequest, :count).by(1)
          .and have_enqueued_job(ExportJob)
      end
    end

    context "when game is nil (export-everything request)" do
      it "creates a request scoped to no game" do
        allow(GameExportRequest).to receive(:valid_receipt_for).with(user, nil).and_return(nil)

        expect {
          described_class.request!(user: user, game: nil)
        }.to change(GameExportRequest, :count).by(1)

        expect(GameExportRequest.last.game).to be_nil
      end
    end
  end

  describe ".email_download_link" do
    it "sends an export_ready mail to the request's user, off the request cycle" do
      request = build_stubbed(:game_export_request, user: user, game: game)
      mail = double(deliver_later: true)
      allow(described_class).to receive(:download_url_for).with(request).and_return("https://x/e.zip")
      allow(ExportMailer).to receive(:export_ready).and_return(mail)

      described_class.email_download_link(request)

      expect(ExportMailer).to have_received(:export_ready)
        .with(user, download_url: "https://x/e.zip", game: game)
      expect(mail).to have_received(:deliver_later)
    end

    it "generates a download URL for the archive" do
      request = request_with_archive
      allow(ExportMailer).to receive(:export_ready).and_return(double(deliver_later: nil))

      described_class.email_download_link(request)

      expect(ExportMailer).to have_received(:export_ready) do |user_arg, download_url:, game:|
        expect(user_arg).to eq(user)
        expect(download_url).to be_present
        expect(game).to eq(game)
      end
    end
  end
end
