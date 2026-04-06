require "rails_helper"

RSpec.describe ExportMailer, type: :mailer do
  let(:user) { create(:user, :with_profile) }
  let(:game) { create(:game) }

  describe "#export_ready" do
    context "with a game" do
      let(:mail) do
        ExportMailer.export_ready(user, download_url: "https://example.com/archive.zip", game: game)
      end

      it "sends to the user email" do
        expect(mail.to).to eq([ user.email ])
      end

      it "includes the game name in the subject" do
        expect(mail.subject).to include(game.name)
        expect(mail.subject).to include("ready")
      end

      it "includes the download URL in the body" do
        expect(mail.body.encoded).to include("https://example.com/archive.zip")
      end

      it "mentions the expiry period" do
        expect(mail.body.encoded).to include("7")
      end
    end

    context "without a game (all-games)" do
      let(:mail) do
        ExportMailer.export_ready(user, download_url: "https://example.com/all.zip")
      end

      it "sends to the user email" do
        expect(mail.to).to eq([ user.email ])
      end

      it "has a generic subject" do
        expect(mail.subject).to include("ready")
      end

      it "includes the download URL" do
        expect(mail.body.encoded).to include("https://example.com/all.zip")
      end
    end
  end

  describe "#export_failed" do
    context "with a game" do
      let(:mail) { ExportMailer.export_failed(user, game: game) }

      it "sends to the user email" do
        expect(mail.to).to eq([ user.email ])
      end

      it "includes the game name in the subject" do
        expect(mail.subject).to include(game.name)
        expect(mail.subject).to include("failed")
      end
    end

    context "without a game (all-games)" do
      let(:mail) { ExportMailer.export_failed(user) }

      it "sends to the user email" do
        expect(mail.to).to eq([ user.email ])
      end

      it "has a generic failed subject" do
        expect(mail.subject).to include("failed")
      end
    end
  end
end
