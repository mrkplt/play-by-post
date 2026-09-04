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

    it "returns the attachment blob path with attachment disposition when a file is attached" do
      attachment = double("blob", attached?: true)
      allow(game_file).to receive(:file).and_return(attachment)
      helpers = double("helpers")
      expect(helpers).to receive(:rails_blob_path).with(attachment, disposition: "attachment").and_return("/blob/path")
      expect(described_class.new(game_file, helpers: helpers).download_url).to eq("/blob/path")
    end
  end

  describe "#delete_url" do
    let(:game) { build_stubbed(:game) }

    it "is nil when the viewer cannot delete this file" do
      helpers = double("helpers")
      expect(described_class.new(game_file, game: game, helpers: helpers, can_delete: false).delete_url).to be_nil
    end

    it "is nil when no can_delete option is supplied at all" do
      helpers = double("helpers")
      expect(described_class.new(game_file, game: game, helpers: helpers).delete_url).to be_nil
    end

    it "returns the game file's delete route for this game and file when the viewer can delete it" do
      helpers = double("helpers")
      expect(helpers).to receive(:game_game_file_path).with(game, game_file).and_return("/games/1/game_files/2")
      expect(described_class.new(game_file, game: game, helpers: helpers, can_delete: true).delete_url)
        .to eq("/games/1/game_files/2")
    end
  end

  # The image branches of thumb_html/lightbox_html run one attachment through
  # helpers.tag.img; asserting the exact <img> (src from url_for, alt from the
  # filename, and the branch-specific class/loading) pins the markup down.
  describe "#thumb_html" do
    it "is nil when there is no thumbnail" do
      allow_any_instance_of(GameFileMediaPresenter).to receive(:thumbnail).and_return(nil)
      expect(presenter.thumb_html).to be_nil
    end

    it "renders a lazy-loaded, class-free img for the thumbnail" do
      thumb = double("thumb")
      allow(game_file).to receive(:filename).and_return("map.png")
      allow_any_instance_of(GameFileMediaPresenter).to receive(:thumbnail).and_return(thumb)
      helpers = ApplicationController.helpers
      allow(helpers).to receive(:url_for).with(thumb).and_return("/thumb.jpg")

      html = described_class.new(game_file, helpers: helpers).thumb_html

      expect(html).to eq(%(<img src="/thumb.jpg" alt="map.png" loading="lazy">))
    end
  end

  describe "#lightbox_html" do
    let(:helpers) { ApplicationController.helpers }

    it "renders the full display image (no lazy load, no class) when this is an image with a display image" do
      display = double("display")
      allow(game_file).to receive(:filename).and_return("hero.jpg")
      allow_any_instance_of(GameFileMediaPresenter).to receive(:image?).and_return(true)
      allow_any_instance_of(GameFileMediaPresenter).to receive(:display_image).and_return(display)
      allow(helpers).to receive(:url_for).with(display).and_return("/display.jpg")

      html = described_class.new(game_file, helpers: helpers).lightbox_html

      expect(html).to eq(%(<img src="/display.jpg" alt="hero.jpg">))
    end

    it "falls back to the constrained thumbnail when there is no display image" do
      thumb = double("thumb")
      allow(game_file).to receive(:filename).and_return("scan.pdf")
      allow_any_instance_of(GameFileMediaPresenter).to receive(:image?).and_return(false)
      allow_any_instance_of(GameFileMediaPresenter).to receive(:thumbnail).and_return(thumb)
      allow(helpers).to receive(:url_for).with(thumb).and_return("/thumb.jpg")

      html = described_class.new(game_file, helpers: helpers).lightbox_html

      expect(html).to eq(%(<img src="/thumb.jpg" alt="scan.pdf" class="max-w-full">))
    end

    it "does not use the display image for a non-image even when one exists (falls back to thumbnail)" do
      thumb = double("thumb")
      display = double("display")
      allow(game_file).to receive(:filename).and_return("scan.pdf")
      allow_any_instance_of(GameFileMediaPresenter).to receive(:image?).and_return(false)
      allow_any_instance_of(GameFileMediaPresenter).to receive(:display_image).and_return(display)
      allow_any_instance_of(GameFileMediaPresenter).to receive(:thumbnail).and_return(thumb)
      allow(helpers).to receive(:url_for).with(thumb).and_return("/thumb.jpg")

      html = described_class.new(game_file, helpers: helpers).lightbox_html

      expect(html).to eq(%(<img src="/thumb.jpg" alt="scan.pdf" class="max-w-full">))
    end

    it "renders a placeholder card with the extension and file size when there is no image or thumbnail" do
      allow_any_instance_of(GameFileMediaPresenter).to receive(:image?).and_return(false)
      allow_any_instance_of(GameFileMediaPresenter).to receive(:thumbnail).and_return(nil)
      allow_any_instance_of(GameFileMediaPresenter).to receive(:file_extension).and_return("PDF")
      allow_any_instance_of(GameFileMediaPresenter).to receive(:human_file_size).and_return("2.1 MB")

      html = described_class.new(game_file, helpers: helpers).lightbox_html

      expect(html).to include('data-testid="lightbox-placeholder"')
      expect(html).to include('data-testid="lightbox-placeholder-ext"')
      expect(html).to include(">PDF<")
      expect(html).to include(">2.1 MB<")
      expect(html).to include("text-meta-500")
      expect(html).to include("text-5xl")
    end
  end
end
