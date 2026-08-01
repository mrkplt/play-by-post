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
