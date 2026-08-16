require "rails_helper"

RSpec.describe GameFilePresenter do
  let(:game_file) { build_stubbed(:game_file) }

  subject(:presenter) { described_class.new(game_file) }

  describe "#filename" do
    it "delegates to the model" do
      expect(presenter.filename).to eq(game_file.filename)
    end
  end

  describe "#file_extension" do
    it "delegates to the media presenter" do
      game_file = build(:game_file, filename: "document.pdf")
      game_file.file.attach(io: StringIO.new("test"), filename: "document.pdf", content_type: "application/pdf")
      expect(described_class.new(game_file).file_extension).to eq("PDF")
    end
  end

  describe "#error?" do
    it "is false when the model carries no error message" do
      allow(game_file).to receive(:error_message).and_return(nil)
      expect(presenter.error?).to be(false)
    end

    it "is true when the model carries an error message" do
      allow(game_file).to receive(:error_message).and_return("too big")
      expect(presenter.error?).to be(true)
    end
  end

  describe "#error_message" do
    it "delegates to the model" do
      allow(game_file).to receive(:error_message).and_return("too big")
      expect(presenter.error_message).to eq("too big")
    end
  end

  describe "#download_url" do
    it "returns '#' when no file is attached" do
      allow(game_file).to receive(:file).and_return(double(attached?: false))
      helpers = double("helpers")
      expect(described_class.new(game_file, helpers: helpers).download_url).to eq("#")
    end

    it "returns the blob path when a file is attached" do
      allow(game_file).to receive(:file).and_return(double(attached?: true))
      helpers = double("helpers", rails_blob_path: "/blob/path")
      expect(described_class.new(game_file, helpers: helpers).download_url).to eq("/blob/path")
    end
  end

  describe "#delete_url" do
    let(:game) { build_stubbed(:game) }

    it "is nil when the viewer cannot manage the game" do
      helpers = double("helpers")
      expect(described_class.new(game_file, game: game, helpers: helpers, can_manage: false).delete_url).to be_nil
    end

    it "returns the game file's delete route when the viewer can manage" do
      helpers = double("helpers", game_game_file_path: "/games/1/game_files/2")
      expect(described_class.new(game_file, game: game, helpers: helpers, can_manage: true).delete_url)
        .to eq("/games/1/game_files/2")
    end
  end

  describe "#thumb_html" do
    it "is nil when there is no thumbnail" do
      allow_any_instance_of(GameFileMediaPresenter).to receive(:thumbnail).and_return(nil)
      expect(presenter.thumb_html).to be_nil
    end
  end

  describe "#lightbox_html" do
    it "renders a placeholder card when there is no image or thumbnail" do
      allow_any_instance_of(GameFileMediaPresenter).to receive(:image?).and_return(false)
      allow_any_instance_of(GameFileMediaPresenter).to receive(:thumbnail).and_return(nil)
      helpers = ApplicationController.helpers
      html = described_class.new(game_file, helpers: helpers).lightbox_html
      expect(html).to include("lightbox-placeholder")
    end
  end
end
