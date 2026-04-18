require "rails_helper"

RSpec.describe Shared::GalleryComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:game_file) do
    gf = build_stubbed(:game_file, filename: "map.pdf")
    allow(gf).to receive(:image?).and_return(false)
    allow(gf).to receive(:display_image).and_return(nil)
    allow(gf).to receive(:file).and_return(double(attached?: false))
    gf
  end

  subject(:component) { described_class.new(game_files: [ game_file ], game: game) }

  def rendered_component
    render_inline(component)
    page
  end

  it "renders the gallery grid" do
    expect(rendered_component).to have_css("[data-testid='gallery-grid']")
  end

  it "renders a gallery card for each file" do
    expect(rendered_component).to have_css("[data-testid='gallery-card']")
  end

  it "renders the filename" do
    expect(rendered_component).to have_css("[data-testid='gallery-card-filename']", text: "map.pdf")
  end

  it "renders the file extension placeholder when no thumbnail" do
    expect(rendered_component).to have_css("[data-testid='gallery-card-placeholder']", text: "PDF")
  end

  it "renders the lightbox modal" do
    expect(rendered_component).to have_css("[data-testid='lightbox']", visible: :hidden)
  end

  context "when is_gm is false" do
    it "does not render the delete button" do
      expect(rendered_component).not_to have_css("[data-lightbox-delete-btn]")
    end
  end

  context "when is_gm is true" do
    subject(:component) { described_class.new(game_files: [ game_file ], game: game, is_gm: true) }

    it "renders the delete button" do
      expect(rendered_component).to have_css("[data-lightbox-delete-btn]", visible: :hidden)
    end
  end

  context "with no files" do
    subject(:component) { described_class.new(game_files: [], game: game) }

    it "renders an empty grid" do
      expect(rendered_component).to have_css("[data-testid='gallery-grid']")
      expect(rendered_component).not_to have_css("[data-testid='gallery-card']")
    end
  end

  context "when the file is attached (download_url_for returns a path, not '#')" do
    let(:game_file) do
      gf = build_stubbed(:game_file, filename: "report.pdf")
      allow(gf).to receive(:image?).and_return(false)
      allow(gf).to receive(:display_image).and_return(nil)
      allow(gf).to receive(:file).and_return(double(attached?: true, content_type: "application/pdf", previewable?: false, byte_size: 1024))
      gf
    end

    it "renders the download path in the card's data attribute" do
      allow_any_instance_of(described_class).to receive(:download_url_for).and_return("/files/report.pdf")
      render_inline(described_class.new(game_files: [ game_file ], game: game))
      expect(page).to have_css("[data-testid='gallery-card']")
      expect(page.native.to_html).to include("/files/report.pdf")
    end
  end

  context "when the file has a thumbnail (thumb_html_for non-nil path)" do
    it "renders an img tag for the thumbnail in the card" do
      allow_any_instance_of(described_class).to receive(:thumb_html_for).and_return('<img src="/thumb.jpg" alt="photo.png">'.html_safe)
      render_inline(described_class.new(game_files: [ game_file ], game: game))
      expect(page).to have_css("[data-testid='gallery-card'] img[src='/thumb.jpg']")
    end
  end

  context "when the file is an image with display_image (lightbox_html_for image branch)" do
    it "stores an img tag without max-w-full in the lightbox data attribute" do
      allow_any_instance_of(described_class).to receive(:lightbox_html_for).and_return('<img src="/display.jpg" alt="photo.png">'.html_safe)
      render_inline(described_class.new(game_files: [ game_file ], game: game))
      expect(page.native.to_html).to include("/display.jpg")
      expect(page.native.to_html).not_to match(/data-lightbox-html="[^"]*max-w-full/)
    end
  end

  context "when file has thumbnail but is not an image (lightbox_html_for elsif branch)" do
    it "stores an img tag with max-w-full in the lightbox data attribute" do
      allow_any_instance_of(described_class).to receive(:lightbox_html_for).and_return('<img src="/thumb.jpg" alt="doc.pdf" class="max-w-full">'.html_safe)
      render_inline(described_class.new(game_files: [ game_file ], game: game))
      expect(page.native.to_html).to include("/thumb.jpg")
      expect(page.native.to_html).to include("max-w-full")
    end
  end
end
