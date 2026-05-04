require "rails_helper"

RSpec.describe ExportJob, type: :job do
  let(:user) { create(:user, :with_profile) }
  let(:game) { create(:game) }
  let!(:game_member) { create(:game_member, :game_master, game: game, user: user) }
  let(:export_request) { create(:game_export_request, user: user, game: game) }

  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
    ActiveJob::Base.queue_adapter = original_adapter
  end

  describe "#perform" do
    it "builds zip via GameExportService, attaches to request, and sends export_ready mail" do
      zip_double = "fake-zip-data"
      service_double = instance_double(GameExportService, call: zip_double)

      allow(GameExportService).to receive(:new).with(user, [ game ]).and_return(service_double)

      archive_double = double
      allow(archive_double).to receive(:attach)
      allow(archive_double).to receive(:blob).and_return(
        double(url: "https://example.com/archive.zip")
      )
      allow(export_request).to receive(:archive).and_return(archive_double)
      allow(GameExportRequest).to receive(:find_by).with(id: export_request.id).and_return(export_request)

      mailer_double = double(deliver_later: true)
      expect(ExportMailer).to receive(:export_ready).with(
        user,
        download_url: "https://example.com/archive.zip",
        game: game
      ).and_return(mailer_double)

      ExportJob.new.perform(export_request.id)
    end

    it "attaches the archive with a slug-based filename" do
      game_with_name = create(:game, name: "The Lost Realm!")
      create(:game_member, :game_master, game: game_with_name, user: user)
      request = create(:game_export_request, user: user, game: game_with_name)

      allow(GameExportService).to receive(:new).and_return(instance_double(GameExportService, call: "zip"))
      archive_double = double
      blob_double = double(url: "https://example.com/x.zip")
      allow(archive_double).to receive(:blob).and_return(blob_double)
      allow(archive_double).to receive(:attach) do |args|
        expect(args[:filename]).to match(/\Athe-lost-realm-export-\d{4}-\d{2}-\d{2}\.zip\z/)
      end
      allow(request).to receive(:archive).and_return(archive_double)
      allow(GameExportRequest).to receive(:find_by).with(id: request.id).and_return(request)
      allow(ExportMailer).to receive(:export_ready).and_return(double(deliver_later: true))

      ExportJob.new.perform(request.id)
    end

    it "does nothing if the request record does not exist" do
      expect(GameExportService).not_to receive(:new)
      expect(ExportMailer).not_to receive(:export_ready)
      expect(ExportMailer).not_to receive(:export_failed)

      ExportJob.new.perform(0)
    end

    it "sends export_failed mail and re-raises on StandardError" do
      allow_any_instance_of(GameExportService).to receive(:call).and_raise(StandardError, "zip failed")

      mailer_double = double(deliver_later: true)
      expect(ExportMailer).to receive(:export_failed).with(user, game: game).and_return(mailer_double)

      expect { ExportJob.new.perform(export_request.id) }.to raise_error(StandardError, "zip failed")
    end

    context "all-games export (game is nil)" do
      let(:game2) { create(:game) }
      let!(:member2) { create(:game_member, game: game2, user: user, status: "active") }
      let(:removed_game) { create(:game) }
      let(:banned_game) { create(:game) }
      let(:all_games_request) { create(:game_export_request, :all_games, user: user) }

      before do
        create(:game_member, :removed, game: removed_game, user: user)
        create(:game_member, :banned, game: banned_game, user: user)
      end

      it "exports all active and removed games, excluding banned" do
        archive_double = double
        allow(archive_double).to receive(:attach)
        allow(archive_double).to receive(:blob).and_return(double(url: "https://example.com/all.zip"))
        allow(all_games_request).to receive(:archive).and_return(archive_double)
        allow(GameExportRequest).to receive(:find_by).with(id: all_games_request.id).and_return(all_games_request)
        allow(ExportMailer).to receive(:export_ready).and_return(double(deliver_later: true))

        expect(GameExportService).to receive(:new) do |_user, games|
          expect(games).to include(game, game2, removed_game)
          expect(games).not_to include(banned_game)
          instance_double(GameExportService, call: "fake-zip")
        end

        ExportJob.new.perform(all_games_request.id)
      end

      it "uses all-games filename" do
        archive_double = double
        allow(archive_double).to receive(:blob).and_return(double(url: "https://example.com/all.zip"))
        allow(archive_double).to receive(:attach) do |args|
          expect(args[:filename]).to match(/\Aall-games-export-\d{4}-\d{2}-\d{2}\.zip\z/)
        end
        allow(all_games_request).to receive(:archive).and_return(archive_double)
        allow(GameExportRequest).to receive(:find_by).with(id: all_games_request.id).and_return(all_games_request)
        allow(GameExportService).to receive(:new).and_return(instance_double(GameExportService, call: "zip"))
        allow(ExportMailer).to receive(:export_ready).and_return(double(deliver_later: true))

        ExportJob.new.perform(all_games_request.id)
      end
    end
  end
end
