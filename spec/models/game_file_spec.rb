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
end
