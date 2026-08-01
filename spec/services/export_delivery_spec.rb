require "rails_helper"

RSpec.describe ExportDelivery, db: true do
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
    it "enqueues an export_ready mail for the request's user" do
      request = request_with_archive

      expect {
        described_class.email_download_link(request)
      }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
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
