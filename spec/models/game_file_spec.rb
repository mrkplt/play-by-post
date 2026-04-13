require "rails_helper"

RSpec.describe GameFile, type: :model do
  describe "validations" do
    it "requires a filename" do
      game_file = build(:game_file, filename: nil)
      expect(game_file).not_to be_valid
    end

    it "is valid with required attributes and a valid file" do
      game_file = build(:game_file)
      game_file.file.attach(io: StringIO.new("test"), filename: "test.pdf", content_type: "application/pdf")
      expect(game_file).to be_valid
    end

    it "rejects files over 25MB" do
      game_file = build(:game_file)
      game_file.file.attach(io: StringIO.new("x" * (26 * 1024 * 1024)), filename: "big.pdf", content_type: "application/pdf")
      expect(game_file).not_to be_valid
      expect(game_file.errors[:file]).to include("must be less than 25MB")
    end

    it "allows a file exactly 25MB" do
      game_file = build(:game_file)
      game_file.file.attach(io: StringIO.new("x" * 25.megabytes), filename: "exact.pdf", content_type: "application/pdf")
      expect(game_file).to be_valid
    end

    it "rejects disallowed content types" do
      game_file = build(:game_file)
      game_file.file.attach(io: StringIO.new("test"), filename: "archive.zip", content_type: "application/zip")
      expect(game_file).not_to be_valid
      expect(game_file.errors[:file]).to include("must be a PDF, Word doc, text, markdown, or image file")
    end

    it "allows PDF content type" do
      game_file = build(:game_file)
      game_file.file.attach(io: StringIO.new("test"), filename: "doc.pdf", content_type: "application/pdf")
      expect(game_file).to be_valid
    end

    it "allows image content types" do
      game_file = build(:game_file)
      game_file.file.attach(io: StringIO.new("test"), filename: "photo.png", content_type: "image/png")
      expect(game_file).to be_valid
    end

    it "does not validate file when not attached" do
      game_file = build(:game_file)
      expect(game_file.errors[:file]).to be_empty
    end
  end

  describe "#image?" do
    it "returns false when no file is attached" do
      game_file = build(:game_file)
      expect(game_file.image?).to be false
    end

    it "returns true for each image content type" do
      %w[image/jpeg image/png image/gif image/webp].each do |content_type|
        game_file = build(:game_file)
        game_file.file.attach(io: StringIO.new("test"), filename: "photo", content_type: content_type)
        expect(game_file.image?).to be(true), "expected true for #{content_type}"
      end
    end

    it "returns false for non-image content types" do
      game_file = build(:game_file)
      game_file.file.attach(io: StringIO.new("test"), filename: "doc.pdf", content_type: "application/pdf")
      expect(game_file.image?).to be false
    end
  end

  describe "#pdf?" do
    it "returns false when no file is attached" do
      game_file = build(:game_file)
      expect(game_file.pdf?).to be false
    end

    it "returns true for PDF content type" do
      game_file = build(:game_file)
      game_file.file.attach(io: StringIO.new("test"), filename: "doc.pdf", content_type: "application/pdf")
      expect(game_file.pdf?).to be true
    end

    it "returns false for non-PDF content types" do
      game_file = build(:game_file)
      game_file.file.attach(io: StringIO.new("test"), filename: "photo.png", content_type: "image/png")
      expect(game_file.pdf?).to be false
    end
  end

  describe "#thumbnailable?" do
    it "returns true for images" do
      game_file = build(:game_file)
      game_file.file.attach(io: StringIO.new("test"), filename: "photo.jpg", content_type: "image/jpeg")
      expect(game_file.thumbnailable?).to be true
    end

    it "returns true for PDFs" do
      game_file = build(:game_file)
      game_file.file.attach(io: StringIO.new("test"), filename: "doc.pdf", content_type: "application/pdf")
      expect(game_file.thumbnailable?).to be true
    end

    it "returns false for text files" do
      game_file = build(:game_file)
      game_file.file.attach(io: StringIO.new("test"), filename: "notes.txt", content_type: "text/plain")
      expect(game_file.thumbnailable?).to be false
    end
  end

  describe "#display_image" do
    it "returns nil when no file is attached" do
      game_file = build(:game_file)
      expect(game_file.display_image).to be_nil
    end

    it "returns nil for a non-image file" do
      game_file = build(:game_file)
      game_file.file.attach(io: StringIO.new("test"), filename: "doc.pdf", content_type: "application/pdf")
      expect(game_file.display_image).to be_nil
    end

    it "returns a variant with correct transformations for an image" do
      game_file = build(:game_file)
      game_file.file.attach(io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
                            filename: "photo.png", content_type: "image/png")
      result = game_file.display_image
      expect(result).to be_a(ActiveStorage::VariantWithRecord)
      expect(result.variation.transformations).to eq(
        resize_to_limit: [ 800, nil ], format: :jpeg, quality: 85
      )
    end
  end

end
