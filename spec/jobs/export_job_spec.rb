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

  describe "#perform (end to end, real attachment)" do
    before do
      allow_any_instance_of(GameExportService).to receive(:call).and_return("zip-bytes")
      allow(ExportMailer).to receive(:export_ready).and_return(double(deliver_later: true))
    end

    # Keep the database: these attach a real archive through Active Storage and
    # serialise the request into a mail job via GlobalID, neither of which has a
    # meaningful stub. Game selection is covered by #games_for below.
    it "attaches a real archive, stamps the receipt, and emails a download link", db: true do
      ExportJob.new.perform(export_request.id)

      export_request.reload
      expect(export_request.archive).to be_attached
      expect(export_request.archive.filename.to_s).to match(/-export-\d{4}-\d{2}-\d{2}\.zip\z/)
      expect(export_request.succeeded_at).to be_present
      expect(ExportMailer).to have_received(:export_ready).with(
        user, hash_including(game: game)
      )
    end
  end

  describe "#perform" do
    it "builds zip via GameExportService, attaches to request, and sends export_ready mail" do
      zip_double = "fake-zip-data"
      service_double = instance_double(GameExportService, call: zip_double)

      allow(GameExportService).to receive(:new).with(user, [ game ]).and_return(service_double)

      archive_double = double
      allow(archive_double).to receive(:blob).and_return(
        double(url: "https://example.com/archive.zip")
      )
      allow(export_request).to receive(:archive).and_return(archive_double)
      allow(export_request).to receive(:mark_succeeded!)
      allow(GameExportRequest).to receive(:find_by).with(id: export_request.id).and_return(export_request)
      allow(AttachmentUploader).to receive(:attach)

      mailer_double = double(deliver_later: true)
      expect(ExportMailer).to receive(:export_ready).with(
        user,
        download_url: "https://example.com/archive.zip",
        game: game
      ).and_return(mailer_double)

      ExportJob.new.perform(export_request.id)

      expect(AttachmentUploader).to have_received(:attach).with(
        hash_including(kind: "export", user: user, game: game, export_scope: game.name)
      )
      expect(export_request).to have_received(:mark_succeeded!)
    end

    it "does not stamp the receipt when the export fails" do
      allow_any_instance_of(GameExportService).to receive(:call).and_raise(StandardError, "boom")
      allow(ExportMailer).to receive(:export_failed).and_return(double(deliver_later: true))
      allow(export_request).to receive(:mark_succeeded!)
      allow(GameExportRequest).to receive(:find_by).with(id: export_request.id).and_return(export_request)

      expect { ExportJob.new.perform(export_request.id) }.to raise_error(StandardError)
      expect(export_request).not_to have_received(:mark_succeeded!)
    end

    it "attaches the archive with a slug-based filename" do
      game_with_name = create(:game, name: "The Lost Realm!")
      create(:game_member, :game_master, game: game_with_name, user: user)
      request = create(:game_export_request, user: user, game: game_with_name)

      allow(GameExportService).to receive(:new).and_return(instance_double(GameExportService, call: "zip"))
      archive_double = double
      allow(archive_double).to receive(:blob).and_return(double(url: "https://example.com/x.zip"))
      allow(request).to receive(:archive).and_return(archive_double)
      allow(GameExportRequest).to receive(:find_by).with(id: request.id).and_return(request)
      allow(ExportMailer).to receive(:export_ready).and_return(double(deliver_later: true))
      allow(AttachmentUploader).to receive(:attach)

      ExportJob.new.perform(request.id)

      expect(AttachmentUploader).to have_received(:attach) do |args|
        expect(args[:original_filename]).to match(/\Athe-lost-realm-export-\d{4}-\d{2}-\d{2}\.zip\z/)
      end
    end

    it "does nothing if the request record does not exist" do
      expect(GameExportService).not_to receive(:new)
      expect(ExportMailer).not_to receive(:export_ready)
      expect(ExportMailer).not_to receive(:export_failed)

      ExportJob.new.perform(0)
    end

    it "sends export_failed mail and re-raises on StandardError" do
      allow_any_instance_of(GameExportService).to receive(:call).and_raise(StandardError, "zip failed")
      allow(GameExportRequest).to receive(:find_by).with(id: export_request.id).and_return(export_request)

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


      it "uses all-games filename and scope" do
        archive_double = double
        allow(archive_double).to receive(:blob).and_return(double(url: "https://example.com/all.zip"))
        allow(all_games_request).to receive(:archive).and_return(archive_double)
        allow(GameExportRequest).to receive(:find_by).with(id: all_games_request.id).and_return(all_games_request)
        allow(GameExportService).to receive(:new).and_return(instance_double(GameExportService, call: "zip"))
        allow(ExportMailer).to receive(:export_ready).and_return(double(deliver_later: true))
        allow(AttachmentUploader).to receive(:attach)

        ExportJob.new.perform(all_games_request.id)

        expect(AttachmentUploader).to have_received(:attach) do |args|
          expect(args[:original_filename]).to match(/\Aall-games-export-\d{4}-\d{2}-\d{2}\.zip\z/)
          expect(args[:export_scope]).to eq("all-games")
        end
      end
    end
  end

  # Game selection is a read isolated behind #games_for, so each case is a
  # relation assertion rather than a persisted membership per status.
  describe "#games_for" do
    let(:selector) { described_class.new }

    it "uses only the requested game when one is given" do
      requested = build_stubbed(:game)

      expect(selector.games_for(build_stubbed(:user), requested)).to eq([ requested ])
    end

    it "returns the games behind active and removed memberships, excluding banned" do
      user = build_stubbed(:user)
      wanted = [ build_stubbed(:game), build_stubbed(:game) ]
      members = wanted.map { |g| build_stubbed(:game_member, game: g) }

      relation = double
      allow(relation).to receive(:where).and_return(relation)
      allow(relation).to receive(:not).and_return(relation)
      allow(relation).to receive(:includes).and_return(relation)
      allow(relation).to receive(:filter_map) { |&blk| members.filter_map(&blk) }
      allow(user).to receive(:game_members).and_return(relation)

      expect(selector.games_for(user, nil)).to eq(wanted)
      expect(relation).to have_received(:where).with(status: %w[active removed])
      expect(relation).to have_received(:not).with(status: "banned")
    end
  end
end
