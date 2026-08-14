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

  let(:view_helpers) { vc_test_view_context }

  def presenter(game_file:, can_manage: false)
    GameFilePresenter.new(game_file, game: game, helpers: view_helpers, can_manage: can_manage)
  end

  subject(:component) { described_class.new(game_files: [ presenter(game_file: game_file) ]) }

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

  context "when can_manage is false" do
    it "does not render the delete button" do
      expect(rendered_component).not_to have_css("[data-lightbox-delete-btn]")
    end

    it "does not set data-lightbox-delete on the gallery card" do
      render_inline(component)
      card = page.find("[data-testid='gallery-card']")
      expect(card["data-lightbox-delete"]).to be_nil
    end
  end

  context "when can_manage is true" do
    subject(:component) { described_class.new(game_files: [ presenter(game_file: game_file, can_manage: true) ], can_manage: true) }

    it "renders the delete button" do
      expect(rendered_component).to have_css("[data-lightbox-delete-btn]", visible: :hidden)
    end

    it "sets data-lightbox-delete on the gallery card" do
      render_inline(component)
      card = page.find("[data-testid='gallery-card']")
      expect(card["data-lightbox-delete"]).to be_present
    end

    it "includes the game and file ids in the delete URL" do
      render_inline(component)
      card = page.find("[data-testid='gallery-card']")
      expect(card["data-lightbox-delete"]).to include("/games/")
      expect(card["data-lightbox-delete"]).to include("/game_files/")
    end
  end

  context "with no files" do
    subject(:component) { described_class.new(game_files: []) }

    it "renders an empty grid" do
      expect(rendered_component).to have_css("[data-testid='gallery-grid']")
      expect(rendered_component).not_to have_css("[data-testid='gallery-card']")
    end
  end

  context "when the file is not attached" do
    it "renders '#' in data-lightbox-download" do
      render_inline(described_class.new(game_files: [ presenter(game_file: game_file) ]))
      card = page.find("[data-testid='gallery-card']")
      expect(card["data-lightbox-download"]).to eq("#")
    end
  end

  context "when the file is attached" do
    let(:attached_game_file) do
      gf = create(:game_file)
      gf.file.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/test_document.pdf")),
        filename: "doc.pdf",
        content_type: "application/pdf"
      )
      gf
    end

    it "renders a blob path (not '#' or empty) in data-lightbox-download when file is attached" do
      render_inline(described_class.new(game_files: [ presenter(game_file: attached_game_file) ]))
      card = page.find("[data-testid='gallery-card']")
      expect(card["data-lightbox-download"]).not_to eq("#")
      expect(card["data-lightbox-download"]).not_to be_empty
    end

    it "renders a path containing 'blob' in data-lightbox-download" do
      render_inline(described_class.new(game_files: [ presenter(game_file: attached_game_file) ]))
      card = page.find("[data-testid='gallery-card']")
      expect(card["data-lightbox-download"]).to include("blob")
    end
  end

  it "stores placeholder HTML with file extension in data-lightbox-html for non-thumbnailable files" do
    render_inline(described_class.new(game_files: [ presenter(game_file: game_file) ]))
    html = page.native.to_html
    lightbox_data = CGI.unescapeHTML(html.match(/data-lightbox-html='([^']*)'/)[1])
    expect(lightbox_data).to include("PDF")
    expect(lightbox_data).to include("lightbox-placeholder")
    expect(lightbox_data).to include('data-testid="lightbox-placeholder"')
    expect(lightbox_data).to include('data-testid="lightbox-placeholder-ext"')
    expect(lightbox_data).to include('class="flex flex-col items-center justify-center')
    expect(lightbox_data).to include('class="text-5xl font-bold text-slate-400"')
    expect(lightbox_data).to include('class="text-sm text-slate-400"')
  end

  context "when the file has a thumbnail" do
    before do
      allow_any_instance_of(GameFilePresenter).to receive(:thumbnail).and_return("/thumb.jpg")
    end

    it "renders an img with correct src, alt, and loading attributes in the card" do
      render_inline(described_class.new(game_files: [ presenter(game_file: game_file) ]))
      expect(page).to have_css("[data-testid='gallery-card'] img[src='/thumb.jpg'][alt='map.pdf'][loading='lazy']")
    end

    it "stores an img with max-w-full and the filename as alt in the lightbox HTML" do
      render_inline(described_class.new(game_files: [ presenter(game_file: game_file) ]))
      html = page.native.to_html
      lightbox_data = CGI.unescapeHTML(html.match(/data-lightbox-html='([^']*)'/)[1])
      expect(lightbox_data).to include('alt="map.pdf"')
      expect(lightbox_data).to include('class="max-w-full"')
    end
  end

  context "when the file is an image with display_image" do
    before do
      allow_any_instance_of(GameFilePresenter).to receive(:image?).and_return(true)
      allow_any_instance_of(GameFilePresenter).to receive(:display_image).and_return("/display.jpg")
    end

    it "stores an img tag without max-w-full in the data-lightbox-html attribute" do
      render_inline(described_class.new(game_files: [ presenter(game_file: game_file) ]))
      html = page.native.to_html
      expect(html).to include("/display.jpg")
      expect(html).not_to include("max-w-full")
    end
  end

  context "when display_image is present but image? is false" do
    before do
      allow_any_instance_of(GameFilePresenter).to receive(:image?).and_return(false)
      allow_any_instance_of(GameFilePresenter).to receive(:display_image).and_return("/display.jpg")
    end

    it "does not render the display image" do
      render_inline(described_class.new(game_files: [ presenter(game_file: game_file) ]))
      expect(page.native.to_html).not_to include("/display.jpg")
    end
  end
end
