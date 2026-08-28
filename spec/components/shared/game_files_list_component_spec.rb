require "rails_helper"

RSpec.describe Shared::GameFilesListComponent, type: :component do
  def file_presenter(filename)
    # The surface GalleryComponent renders per row.
    instance_double(
      GameFilePresenter,
      filename: filename,
      lightbox_html: "<img>",
      download_url: "/d/#{filename}",
      delete_url: nil,
      thumb_html: nil,
      file_extension: "PDF"
    )
  end

  it "renders the empty state and no gallery when there are no files" do
    render_inline(described_class.new(game_files: []))
    expect(page).to have_text(Shared::GameFilesListComponent::EMPTY)
    expect(page).to have_no_css("[data-testid='gallery-grid']")
  end

  it "renders the newest-first label (not the empty state) when files are present" do
    render_inline(described_class.new(game_files: [ file_presenter("a.pdf") ]))
    expect(page).to have_text("Newest first")
    expect(page).to have_no_text(Shared::GameFilesListComponent::EMPTY)
  end

  it "wraps its content in the stable id" do
    render_inline(described_class.new(game_files: []))
    expect(page).to have_css("##{Shared::GameFilesListComponent::DOM_ID}")
  end
end
