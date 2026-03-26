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

    it "rejects disallowed content types" do
      game_file = build(:game_file)
      game_file.file.attach(io: StringIO.new("test"), filename: "archive.zip", content_type: "application/zip")
      expect(game_file).not_to be_valid
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
  end

  describe "#image?" do
    it "returns true for image content types" do
      game_file = build(:game_file)
      game_file.file.attach(io: StringIO.new("test"), filename: "photo.png", content_type: "image/png")
      expect(game_file.image?).to be true
    end

    it "returns false for non-image content types" do
      game_file = build(:game_file)
      game_file.file.attach(io: StringIO.new("test"), filename: "doc.pdf", content_type: "application/pdf")
      expect(game_file.image?).to be false
    end
  end

  describe "#pdf?" do
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

  describe "#file_extension" do
    it "returns uppercase extension from filename" do
      game_file = build(:game_file, filename: "document.pdf")
      game_file.file.attach(io: StringIO.new("test"), filename: "document.pdf", content_type: "application/pdf")
      expect(game_file.file_extension).to eq("PDF")
    end

    it "returns extension from content type when filename has no extension" do
      game_file = build(:game_file, filename: "document")
      game_file.file.attach(io: StringIO.new("test"), filename: "document", content_type: "text/plain")
      expect(game_file.file_extension).to eq("TXT")
    end
  end
end
