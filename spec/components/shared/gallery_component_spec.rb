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

  context "when the file is not attached (download_url_for false branch)" do
    it "renders '#' in data-lightbox-download" do
      render_inline(described_class.new(game_files: [ game_file ], game: game))
      expect(page).to have_css('[data-lightbox-download="#"]')
    end
  end

  context "when the file is attached (download_url_for true branch)" do
    let(:attached_game_file) do
      gf = create(:game_file)
      gf.file.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/test_document.pdf")),
        filename: "doc.pdf",
        content_type: "application/pdf"
      )
      gf
    end

    it "renders a blob path (not '#') in data-lightbox-download when file is attached" do
      render_inline(described_class.new(game_files: [ attached_game_file ], game: attached_game_file.game))
      card = page.find("[data-testid='gallery-card']")
      expect(card["data-lightbox-download"]).not_to eq("#")
    end
  end

  context "when the file has a thumbnail (thumb_html_for non-nil path)" do
    before do
      allow_any_instance_of(GameFilePresenter).to receive(:thumbnail).and_return("/thumb.jpg")
    end

    it "renders an img tag for the thumbnail in the card" do
      render_inline(described_class.new(game_files: [ game_file ], game: game))
      expect(page).to have_css("[data-testid='gallery-card'] img[src='/thumb.jpg']")
    end
  end

  context "when the file is an image with display_image (lightbox_html_for image branch)" do
    before do
      allow_any_instance_of(GameFilePresenter).to receive(:image?).and_return(true)
      allow_any_instance_of(GameFilePresenter).to receive(:display_image).and_return("/display.jpg")
    end

    it "stores an img tag without max-w-full in the data-lightbox-html attribute" do
      render_inline(described_class.new(game_files: [ game_file ], game: game))
      html = page.native.to_html
      expect(html).to include("/display.jpg")
      expect(html).not_to include("max-w-full")
    end
  end

  context "when file has thumbnail but is not an image (lightbox_html_for elsif branch)" do
    before do
      allow_any_instance_of(GameFilePresenter).to receive(:thumbnail).and_return("/thumb.jpg")
    end

    it "stores an img with max-w-full in the data-lightbox-html attribute" do
      render_inline(described_class.new(game_files: [ game_file ], game: game))
      html = page.native.to_html
      expect(html).to include("/thumb.jpg")
      expect(html).to include("max-w-full")
    end
  end
end
