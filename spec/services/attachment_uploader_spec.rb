require "rails_helper"

RSpec.describe AttachmentUploader do
  let(:game) { create(:game) }
  let(:user) { create(:user, :with_profile) }

  describe ".attach" do
    it "prefixes the blob key with the kind's namespace" do
      game_file = game.game_files.new(filename: "map.pdf")

      described_class.attach(
        attachment: game_file.file,
        attachable: { io: StringIO.new("data"), filename: "map.pdf", content_type: "application/pdf" },
        kind: "game_file",
        user: user,
        game: game,
        original_filename: "map.pdf"
      )

      expect(game_file.file.key).to start_with("game_files/")
    end

    it "generates a unique key per upload under the prefix" do
      keys = Array.new(2) do
        gf = game.game_files.new(filename: "map.pdf")
        described_class.attach(
          attachment: gf.file,
          attachable: { io: StringIO.new("data"), filename: "map.pdf", content_type: "application/pdf" },
          kind: "game_file", user: user, game: game, original_filename: "map.pdf"
        )
        gf.file.key
      end

      expect(keys.first).not_to eq(keys.last)
      expect(keys).to all(match(%r{\Agame_files/[a-z0-9]+\z}))
    end

    it "uses the exports/ prefix for export archives" do
      request = create(:game_export_request, user: user, game: game)

      described_class.attach(
        attachment: request.archive,
        attachable: { io: StringIO.new("zip"), filename: "e.zip", content_type: "application/zip" },
        kind: "export",
        user: user,
        game: game,
        original_filename: "e.zip",
        export_scope: "all-games"
      )

      expect(request.archive.key).to start_with("exports/")
    end

    it "writes custom metadata onto the blob" do
      game_file = game.game_files.new(filename: "map.pdf")

      described_class.attach(
        attachment: game_file.file,
        attachable: { io: StringIO.new("data"), filename: "map.pdf", content_type: "application/pdf" },
        kind: "game_file",
        user: user,
        game: game,
        original_filename: "map.pdf"
      )

      blob = game_file.file.blob
      expect(blob.content_type).to eq("application/pdf")
      expect(blob.filename.to_s).to eq("map.pdf")
      metadata = blob.custom_metadata
      expect(metadata["kind"]).to eq("game_file")
      expect(metadata["game-id"]).to eq(game.id.to_s)
      expect(metadata["user-id"]).to eq(user.id.to_s)
      expect(metadata["original-filename"]).to eq("map.pdf")
      expect(metadata["uploaded-at"]).to be_present
    end

    it "sets the blob content_type from the provided value, not filename inference" do
      game_file = game.game_files.new(filename: "data")

      described_class.attach(
        attachment: game_file.file,
        attachable: { io: StringIO.new("data"), filename: "data", content_type: "application/pdf" },
        kind: "game_file", user: user, game: game, original_filename: "data"
      )

      expect(game_file.file.blob.content_type).to eq("application/pdf")
    end

    it "passes export_scope through to the blob metadata" do
      request = create(:game_export_request, user: user, game: game)

      described_class.attach(
        attachment: request.archive,
        attachable: { io: StringIO.new("zip"), filename: "e.zip", content_type: "application/zip" },
        kind: "export",
        user: user,
        game: game,
        original_filename: "e.zip",
        export_scope: "all-games"
      )

      expect(request.archive.blob.custom_metadata["export-scope"]).to eq("all-games")
    end

    it "does not double-prefix an already-prefixed key" do
      game_file = game.game_files.new(filename: "map.pdf")

      described_class.attach(
        attachment: game_file.file,
        attachable: { io: StringIO.new("data"), filename: "map.pdf", content_type: "application/pdf" },
        kind: "game_file"
      )

      expect(game_file.file.key).to start_with("game_files/")
      expect(game_file.file.key).not_to start_with("game_files/game_files/")
    end

    it "raises for an unknown kind" do
      game_file = game.game_files.new(filename: "map.pdf")

      expect {
        described_class.attach(
          attachment: game_file.file,
          attachable: { io: StringIO.new("data"), filename: "map.pdf", content_type: "application/pdf" },
          kind: "bogus"
        )
      }.to raise_error(KeyError)
    end
  end

  describe "derived variant assets" do
    it "prefixes variant blob keys with variants/", db: true do
      game_file = game.game_files.new(filename: "map.png")
      described_class.attach(
        attachment: game_file.file,
        attachable: {
          io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
          filename: "map.png", content_type: "image/png"
        },
        kind: "game_file", user: user, game: game, original_filename: "map.png"
      )
      game_file.save!

      variant = game_file.file.variant(resize_to_limit: [ 50, 50 ]).processed

      expect(variant.key).to start_with("variants/")
    end

    it "prefixes extracted preview image keys with previews/" do
      # Drive Preview#process with a stubbed previewer that yields a fake
      # extracted image, so the test does not depend on a system PDF previewer
      # (poppler/mupdf) being installed in CI — it exercises only our key wrap.
      game_file = game.game_files.new(filename: "rules.pdf")
      described_class.attach(
        attachment: game_file.file,
        attachable: {
          io: StringIO.new("%PDF-1.4 fake"),
          filename: "rules.pdf", content_type: "application/pdf"
        },
        kind: "game_file", user: user, game: game, original_filename: "rules.pdf"
      )
      game_file.save!

      blob = game_file.file.blob
      preview = ActiveStorage::Preview.new(blob, resize_to_limit: [ 50, 50 ])
      fake_previewer = double("previewer")
      allow(fake_previewer).to receive(:preview) do |**_opts, &block|
        block.call(
          io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
          filename: "rules.png", content_type: "image/png"
        )
      end
      allow(preview).to receive(:previewer).and_return(fake_previewer)

      preview.send(:process)

      expect(blob.preview_image.key).to start_with("previews/")
    end
  end

  describe ".normalize" do
    it "reads io, filename, and content_type from a hash attachable" do
      io = StringIO.new("data")
      result = described_class.normalize({ io: io, filename: "n.pdf", content_type: "application/pdf" })

      expect(result).to eq([ io, "n.pdf", "application/pdf" ])
    end

    it "returns a nil content_type when the hash omits it" do
      io = StringIO.new("data")
      result = described_class.normalize({ io: io, filename: "n.pdf" })

      expect(result).to eq([ io, "n.pdf", nil ])
    end

    it "reads original_filename and content_type from an uploaded file" do
      uploaded = Rack::Test::UploadedFile.new(StringIO.new("data"), "image/png", original_filename: "a.png")
      io, filename, content_type = described_class.normalize(uploaded)

      expect(filename).to eq("a.png")
      expect(content_type).to eq("image/png")
      expect(io).not_to be_nil
    end
  end

  describe ".build_metadata" do
    it "maps each input to its expected metadata key" do
      metadata = described_class.build_metadata(
        kind: "export", user: user, game: game,
        original_filename: "e.zip", export_scope: "all-games"
      )
      expect(metadata).to include(
        "kind" => "export",
        "game-id" => game.id.to_s,
        "user-id" => user.id.to_s,
        "original-filename" => "e.zip",
        "export-scope" => "all-games"
      )
    end

    it "omits export-scope when nil" do
      metadata = described_class.build_metadata(
        kind: "game_file", user: user, game: game,
        original_filename: "e.pdf", export_scope: nil
      )
      expect(metadata).not_to have_key("export-scope")
    end

    it "stamps uploaded-at as a UTC ISO8601 string" do
      Timecop.freeze(Time.utc(2026, 7, 29, 15, 30, 45)) do
        metadata = described_class.build_metadata(
          kind: "game_file", user: user, game: game,
          original_filename: "e.pdf", export_scope: nil
        )
        # Assert the class too: ActiveSupport's Time#== coerces the string, so a
        # bare Time would still `eq` this — be_a(String) catches a dropped .iso8601.
        expect(metadata["uploaded-at"]).to be_a(String).and eq("2026-07-29T15:30:45Z")
      end
    end

    it "omits nil values" do
      metadata = described_class.build_metadata(
        kind: "post_image", user: nil, game: nil,
        original_filename: nil, export_scope: nil
      )
      expect(metadata.keys).to contain_exactly("kind", "uploaded-at")
    end
  end
end
