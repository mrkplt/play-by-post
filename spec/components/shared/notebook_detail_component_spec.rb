require "rails_helper"

RSpec.describe Shared::NotebookDetailComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:entry) { build_stubbed(:notebook_entry, game: game, title: "Lore", slug: "abc123def456ghij", body: "# Heading\n\nBody text.") }

  def build_component(**overrides)
    described_class.new(**{ game: game, notebook_entry: entry }.merge(overrides))
  end

  describe "GM actions" do
    it "always shows Edit and Delete" do
      render_inline(build_component)
      expect(page).to have_link("Edit")
      expect(page).to have_button("Delete")
    end

    it "shows Promote when not yet promoted" do
      render_inline(build_component)
      expect(page).to have_button("Promote")
    end

    it "hides Promote and shows a Promoted-to link once promoted" do
      page_record = build_stubbed(:page, game: game, title: "Promoted Page", slug: "pagepageslug1234")
      promoted_entry = build_stubbed(:notebook_entry, game: game, slug: "promotedentry123", promoted_page: page_record)
      render_inline(build_component(notebook_entry: promoted_entry))

      expect(page).to have_no_button("Promote")
      expect(page).to have_link("Promoted to: Promoted Page")
    end
  end

  describe "empty state" do
    it "shows a placeholder when there is no body" do
      render_inline(build_component(notebook_entry: build_stubbed(:notebook_entry, game: game, slug: "nobodyslug123456", body: nil)))
      expect(page).to have_text("no content yet")
    end
  end
end
