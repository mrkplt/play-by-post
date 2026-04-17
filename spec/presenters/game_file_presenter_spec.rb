require "rails_helper"

RSpec.describe GameFilePresenter do
  let(:game_file) { build_stubbed(:game_file) }

  subject(:presenter) { described_class.new(game_file) }

  describe "#human_file_size" do
    context "when no file is attached" do
      before { allow(game_file).to receive(:file).and_return(double(attached?: false)) }

      it { expect(presenter.human_file_size).to eq("") }
    end

    context "when a file is attached" do
      before do
        allow(game_file).to receive(:file).and_return(
          double(attached?: true, byte_size: 2_048)
        )
      end

      it "returns a human-readable size" do
        expect(presenter.human_file_size).to eq("2 KB")
      end
    end
  end

  describe "#image?" do
    it "returns false when no file is attached" do
      game_file = build(:game_file)
      expect(described_class.new(game_file).image?).to be false
    end

    it "returns true for each image content type" do
      %w[image/jpeg image/png image/gif image/webp].each do |content_type|
        game_file = build(:game_file)
        game_file.file.attach(io: StringIO.new("test"), filename: "photo", content_type: content_type)
        expect(described_class.new(game_file).image?).to be(true), "expected true for #{content_type}"
      end
    end

    it "returns false for non-image content types" do
      game_file = build(:game_file)
      game_file.file.attach(io: StringIO.new("test"), filename: "doc.pdf", content_type: "application/pdf")
      expect(described_class.new(game_file).image?).to be false
    end
  end

  describe "#thumbnail" do
    it "returns nil when no file is attached" do
      game_file = build(:game_file)
      expect(described_class.new(game_file).thumbnail).to be_nil
    end

    it "returns a variant with correct transformations for an image" do
      game_file = build(:game_file)
      game_file.file.attach(io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
                            filename: "photo.png", content_type: "image/png")
      result = described_class.new(game_file).thumbnail
      expect(result).to be_a(ActiveStorage::VariantWithRecord)
      expect(result.variation.transformations).to eq(
        resize_to_limit: [ 240, 240 ], format: :jpeg, quality: 80
      )
    end

    it "returns a preview with correct transformations for a previewable PDF" do
      game_file = build(:game_file)
      game_file.file.attach(io: StringIO.new("test"), filename: "doc.pdf", content_type: "application/pdf")
      allow(game_file.file).to receive(:previewable?).and_return(true)
      expected_transformations = { resize_to_limit: [ 240, 240 ], format: :jpeg, quality: 80 }
      fake_preview = ActiveStorage::Preview.allocate
      allow(fake_preview).to receive(:variation).and_return(ActiveStorage::Variation.new(expected_transformations))
      allow(game_file.file).to receive(:preview).with(expected_transformations).and_return(fake_preview)
      result = described_class.new(game_file).thumbnail
      expect(result).to be_a(ActiveStorage::Preview)
      expect(result.variation.transformations).to eq(expected_transformations)
    end

    it "returns nil for a PDF that is not previewable" do
      game_file = build(:game_file)
      game_file.file.attach(io: StringIO.new("test"), filename: "doc.pdf", content_type: "application/pdf")
      allow(game_file.file).to receive(:previewable?).and_return(false)
      expect(described_class.new(game_file).thumbnail).to be_nil
    end

    it "returns nil for a non-image non-PDF file even if previewable" do
      game_file = build(:game_file)
      game_file.file.attach(io: StringIO.new("test"), filename: "notes.txt", content_type: "text/plain")
      allow(game_file.file).to receive(:previewable?).and_return(true)
      expect(described_class.new(game_file).thumbnail).to be_nil
    end
  end

  describe "#file_extension" do
    it "returns uppercase extension from filename" do
      game_file = build(:game_file, filename: "document.pdf")
      game_file.file.attach(io: StringIO.new("test"), filename: "document.pdf", content_type: "application/pdf")
      expect(described_class.new(game_file).file_extension).to eq("PDF")
    end

    it "returns extension from content type when filename has no extension" do
      game_file = build(:game_file, filename: "document")
      game_file.file.attach(io: StringIO.new("test"), filename: "document", content_type: "text/plain")
      expect(described_class.new(game_file).file_extension).to eq("TXT")
    end

    it "returns DOC for msword content type" do
      game_file = build(:game_file, filename: "document")
      game_file.file.attach(io: StringIO.new("test"), filename: "document", content_type: "application/msword")
      expect(described_class.new(game_file).file_extension).to eq("DOC")
    end

    it "returns DOCX for openxml word content type" do
      game_file = build(:game_file, filename: "document")
      game_file.file.attach(io: StringIO.new("test"), filename: "document",
                            content_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
      expect(described_class.new(game_file).file_extension).to eq("DOCX")
    end

    it "returns MD for markdown content type" do
      game_file = build(:game_file, filename: "notes")
      game_file.file.attach(io: StringIO.new("test"), filename: "notes", content_type: "text/markdown")
      expect(described_class.new(game_file).file_extension).to eq("MD")
    end

    it "returns PDF for pdf content type" do
      game_file = build(:game_file, filename: "document")
      game_file.file.attach(io: StringIO.new("test"), filename: "document", content_type: "application/pdf")
      expect(described_class.new(game_file).file_extension).to eq("PDF")
    end

    it "returns FILE for unknown content type when filename has no extension" do
      game_file = build(:game_file, filename: "data")
      game_file.file.attach(io: StringIO.new("test"), filename: "data", content_type: "application/octet-stream")
      expect(described_class.new(game_file).file_extension).to eq("FILE")
    end

    it "returns empty string when no file attached and filename has no extension" do
      game_file = build(:game_file, filename: "document")
      expect(described_class.new(game_file).file_extension).to eq("")
    end
  end

  describe "#filename" do
    it "delegates to the model" do
      expect(presenter.filename).to eq(game_file.filename)
    end
  end

  describe "#display_image" do
    it "returns nil when no image is attached" do
      game_file = build(:game_file)
      expect(described_class.new(game_file).display_image).to be_nil
    end

    it "returns a variant for an attached image" do
      game_file = build(:game_file)
      game_file.file.attach(io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
                            filename: "photo.png", content_type: "image/png")
      result = described_class.new(game_file).display_image
      expect(result).to be_a(ActiveStorage::VariantWithRecord)
    end

    it "returns nil for a non-image file" do
      game_file = build(:game_file)
      game_file.file.attach(io: StringIO.new("test"), filename: "doc.pdf", content_type: "application/pdf")
      expect(described_class.new(game_file).display_image).to be_nil
    end
  end

  describe "#file" do
    it "delegates to the model" do
      expect(presenter.file).to eq(game_file.file)
    end
  end
end
