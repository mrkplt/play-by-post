require "rails_helper"

RSpec.describe Shared::GalleryComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:game_file) do
    gf = build_stubbed(:game_file, filename: "map.pdf")
    allow(gf).to receive(:thumbnail).and_return(nil)
    allow(gf).to receive(:image?).and_return(false)
    allow(gf).to receive(:display_image).and_return(nil)
    allow(gf).to receive(:file_extension).and_return("PDF")
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
end
