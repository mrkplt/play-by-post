require "rails_helper"

RSpec.describe ExportTarget do
  let(:user) { build_stubbed(:user) }
  let(:request) { build_stubbed(:game_export_request) }

  describe "#attach" do
    before { allow(AttachmentUploader).to receive(:attach) }

    it "attaches a slugified, dated filename and scope for a named game" do
      Timecop.freeze(Time.zone.local(2026, 3, 4)) do
        game = build_stubbed(:game, name: "The Lost Realm!")

        described_class.new(game).attach(request: request, zip_data: "zip-bytes", user: user)

        expect(AttachmentUploader).to have_received(:attach) do |args|
          expect(args[:attachment]).to eq(request.archive)
          expect(args[:context].kind).to eq("export")
          expect(args[:context].owner.user).to eq(user)
          expect(args[:context].owner.game).to eq(game)
          expect(args[:context].naming.original_filename).to eq("the-lost-realm-export-2026-03-04.zip")
          expect(args[:context].naming.export_scope).to eq("The Lost Realm!")
          expect(args[:attachable][:filename]).to eq("the-lost-realm-export-2026-03-04.zip")
          expect(args[:attachable][:content_type]).to eq("application/zip")
        end
      end
    end

    it "uses an all-games filename and scope when there is no game" do
      Timecop.freeze(Time.zone.local(2026, 3, 4)) do
        described_class.new(nil).attach(request: request, zip_data: "zip-bytes", user: user)

        expect(AttachmentUploader).to have_received(:attach) do |args|
          expect(args[:context].owner.game).to be_nil
          expect(args[:context].naming.original_filename).to eq("all-games-export-2026-03-04.zip")
          expect(args[:context].naming.export_scope).to eq("all-games")
        end
      end
    end

    it "strips characters that are not safe for a filename slug" do
      game = build_stubbed(:game, name: "Foo & Bar: The  Sequel")

      described_class.new(game).attach(request: request, zip_data: "z", user: user)

      expect(AttachmentUploader).to have_received(:attach) do |args|
        expect(args[:context].naming.original_filename).to match(/\Afoo-bar-the-sequel-export-\d{4}-\d{2}-\d{2}\.zip\z/)
      end
    end

    it "collapses a literal double hyphen down to one" do
      game = build_stubbed(:game, name: "Foo -- Bar")

      described_class.new(game).attach(request: request, zip_data: "z", user: user)

      expect(AttachmentUploader).to have_received(:attach) do |args|
        expect(args[:context].naming.original_filename).to match(/\Afoo-bar-export-\d{4}-\d{2}-\d{2}\.zip\z/)
      end
    end

    it "collapses every run of dashes, not just the first" do
      game = build_stubbed(:game, name: "Foo  --  Bar   ---   Baz")

      described_class.new(game).attach(request: request, zip_data: "z", user: user)

      expect(AttachmentUploader).to have_received(:attach) do |args|
        expect(args[:context].naming.original_filename).to match(/\Afoo-bar-baz-export-\d{4}-\d{2}-\d{2}\.zip\z/)
      end
    end

    it "wraps the zip bytes in the attachable IO" do
      described_class.new(nil).attach(request: request, zip_data: "the-bytes", user: user)

      expect(AttachmentUploader).to have_received(:attach) do |args|
        expect(args[:attachable][:io].read).to eq("the-bytes")
      end
    end
  end
end
