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

    it "does not set data-lightbox-delete on the gallery card" do
      render_inline(component)
      card = page.find("[data-testid='gallery-card']")
      expect(card["data-lightbox-delete"]).to be_nil
    end
  end

  context "when is_gm is true" do
    subject(:component) { described_class.new(game_files: [ game_file ], game: game, is_gm: true) }

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
    subject(:component) { described_class.new(game_files: [], game: game) }

    it "renders an empty grid" do
      expect(rendered_component).to have_css("[data-testid='gallery-grid']")
      expect(rendered_component).not_to have_css("[data-testid='gallery-card']")
    end
  end

  context "when the file is not attached (download_url_for false branch)" do
    it "renders '#' in data-lightbox-download" do
      render_inline(described_class.new(game_files: [ game_file ], game: game))
      card = page.find("[data-testid='gallery-card']")
      expect(card["data-lightbox-download"]).to eq("#")
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

    it "renders a blob path (not '#' or empty) in data-lightbox-download when file is attached" do
      render_inline(described_class.new(game_files: [ attached_game_file ], game: attached_game_file.game))
      card = page.find("[data-testid='gallery-card']")
      expect(card["data-lightbox-download"]).not_to eq("#")
      expect(card["data-lightbox-download"]).not_to be_empty
    end

    it "renders a path containing 'blob' in data-lightbox-download" do
      render_inline(described_class.new(game_files: [ attached_game_file ], game: attached_game_file.game))
      card = page.find("[data-testid='gallery-card']")
      expect(card["data-lightbox-download"]).to include("blob")
    end
  end

  it "stores placeholder HTML with file extension in data-lightbox-html for non-thumbnailable files" do
    render_inline(described_class.new(game_files: [ game_file ], game: game))
    html = page.native.to_html
    lightbox_data = CGI.unescapeHTML(html.match(/data-lightbox-html='([^']*)'/)[1])
    expect(lightbox_data).to include("PDF")
    expect(lightbox_data).to include("lightbox-placeholder")
  end

  it "stores the outer placeholder div with correct testid in data-lightbox-html" do
    render_inline(described_class.new(game_files: [ game_file ], game: game))
    html = page.native.to_html
    lightbox_data = CGI.unescapeHTML(html.match(/data-lightbox-html='([^']*)'/)[1])
    expect(lightbox_data).to include('data-testid="lightbox-placeholder"')
  end

  it "stores the extension div with correct testid in data-lightbox-html" do
    render_inline(described_class.new(game_files: [ game_file ], game: game))
    html = page.native.to_html
    lightbox_data = CGI.unescapeHTML(html.match(/data-lightbox-html='([^']*)'/)[1])
    expect(lightbox_data).to include('data-testid="lightbox-placeholder-ext"')
  end

  it "stores outer placeholder div CSS classes in data-lightbox-html" do
    render_inline(described_class.new(game_files: [ game_file ], game: game))
    html = page.native.to_html
    lightbox_data = CGI.unescapeHTML(html.match(/data-lightbox-html='([^']*)'/)[1])
    expect(lightbox_data).to include("flex")
    expect(lightbox_data).to include("flex-col")
    expect(lightbox_data).to include("items-center")
    expect(lightbox_data).to include("justify-center")
    expect(lightbox_data).to include("text-slate-500")
    expect(lightbox_data).to include('class="flex flex-col items-center justify-center')
  end

  it "stores extension div CSS classes in data-lightbox-html" do
    render_inline(described_class.new(game_files: [ game_file ], game: game))
    html = page.native.to_html
    lightbox_data = CGI.unescapeHTML(html.match(/data-lightbox-html='([^']*)'/)[1])
    expect(lightbox_data).to include("text-5xl")
    expect(lightbox_data).to include("font-bold")
    expect(lightbox_data).to include("text-slate-400")
    expect(lightbox_data).to include("lightbox-placeholder-ext")
    expect(lightbox_data).to include('class="text-5xl font-bold text-slate-400"')
  end

  it "stores the file size div with text-sm class in data-lightbox-html" do
    render_inline(described_class.new(game_files: [ game_file ], game: game))
    html = page.native.to_html
    lightbox_data = CGI.unescapeHTML(html.match(/data-lightbox-html='([^']*)'/)[1])
    expect(lightbox_data).to include('class="text-sm text-slate-400"')
  end

  context "when the file has a thumbnail (thumb_html_for non-nil path)" do
    before do
      allow_any_instance_of(GameFilePresenter).to receive(:thumbnail).and_return("/thumb.jpg")
    end

    it "renders an img with correct src, alt, and loading attributes in the card" do
      render_inline(described_class.new(game_files: [ game_file ], game: game))
      expect(page).to have_css("[data-testid='gallery-card'] img[src='/thumb.jpg'][alt='map.pdf'][loading='lazy']")
    end

    it "stores the filename as alt attribute in the lightbox thumb HTML" do
      render_inline(described_class.new(game_files: [ game_file ], game: game))
      html = page.native.to_html
      lightbox_data = CGI.unescapeHTML(html.match(/data-lightbox-html='([^']*)'/)[1])
      expect(lightbox_data).to include('alt="map.pdf"')
    end

    it "stores max-w-full as a class attribute in the lightbox thumb HTML" do
      render_inline(described_class.new(game_files: [ game_file ], game: game))
      html = page.native.to_html
      lightbox_data = CGI.unescapeHTML(html.match(/data-lightbox-html='([^']*)'/)[1])
      expect(lightbox_data).to include('class="max-w-full"')
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

    it "stores the filename as alt attribute in the lightbox image HTML" do
      render_inline(described_class.new(game_files: [ game_file ], game: game))
      html = page.native.to_html
      lightbox_data = CGI.unescapeHTML(html.match(/data-lightbox-html='([^']*)'/)[1])
      expect(lightbox_data).to include('alt="map.pdf"')
    end
  end

  context "when display_image is present but image? is false (lightbox_html_for uses elsif/else)" do
    before do
      allow_any_instance_of(GameFilePresenter).to receive(:image?).and_return(false)
      allow_any_instance_of(GameFilePresenter).to receive(:display_image).and_return("/display.jpg")
    end

    it "does not render the display image when image? is false" do
      render_inline(described_class.new(game_files: [ game_file ], game: game))
      expect(page.native.to_html).not_to include("/display.jpg")
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

    it "stores the filename as alt attribute in the lightbox thumb HTML" do
      render_inline(described_class.new(game_files: [ game_file ], game: game))
      html = page.native.to_html
      lightbox_data = CGI.unescapeHTML(html.match(/data-lightbox-html='([^']*)'/)[1])
      expect(lightbox_data).to include("map.pdf")
    end
  end
end
