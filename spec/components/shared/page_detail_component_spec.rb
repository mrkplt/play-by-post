require "rails_helper"

RSpec.describe Shared::PageDetailComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:page_record) { build_stubbed(:page, game: game, title: "Lore", slug: "abc123def456ghij", body: "# Heading\n\nBody text.") }

  def build_component(**overrides)
    described_class.new(**{ game: game, page: page_record, is_gm: false }.merge(overrides))
  end

  describe "#rendered_body" do
    it "renders the markdown body to HTML" do
      expect(build_component.rendered_body).to include("<h1>Heading</h1>")
    end

    it "reports whether the body is present" do
      expect(build_component(page: page_record).body?).to be(true)
      expect(build_component(page: build_stubbed(:page, game: game, body: nil)).body?).to be(false)
    end
  end

  describe "GM affordances" do
    it "shows Edit and Delete to the GM" do
      render_inline(build_component(is_gm: true))
      expect(page).to have_link("Edit")
      expect(page).to have_button("Delete")
    end

    it "hides Edit and Delete from a non-GM" do
      render_inline(build_component(is_gm: false))
      expect(page).to have_no_link("Edit")
      expect(page).to have_no_button("Delete")
    end
  end

  describe "empty state" do
    it "shows a placeholder when there is no body" do
      render_inline(build_component(page: build_stubbed(:page, game: game, body: nil)))
      expect(page).to have_text("no content yet")
    end
  end
end
