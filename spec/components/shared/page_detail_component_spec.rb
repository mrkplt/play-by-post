require "rails_helper"

RSpec.describe Shared::PageDetailComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:urls) { Rails.application.routes.url_helpers }
  let(:page_record) { build_stubbed(:page, game: game, title: "Lore", slug: "abc123def456ghij", body: "# Heading\n\nBody text.") }

  def presenter_for(page_record, can_manage: false)
    PagePresenter.new(page_record, page_policy: instance_double(PagePolicy, manage?: can_manage),
                                   game_policy: instance_double(GamePolicy, manage?: can_manage),
                                   game: game, urls: urls)
  end

  def build_component(page_record: self.page_record, can_manage: false)
    described_class.new(page: presenter_for(page_record, can_manage: can_manage))
  end

  describe "GM affordances" do
    it "shows Edit and Delete to the GM" do
      render_inline(build_component(can_manage: true))
      expect(page).to have_link("Edit")
      expect(page).to have_button("Delete")
    end

    it "hides Edit and Delete from a non-GM" do
      render_inline(build_component(can_manage: false))
      expect(page).to have_no_link("Edit")
      expect(page).to have_no_button("Delete")
    end
  end

  describe "draft affordances" do
    let(:draft_page) { build_stubbed(:page, game: game, slug: "draftslug0000000", draft: true) }

    it "shows a Draft badge and Publish button to the GM on a draft page" do
      render_inline(build_component(page_record: draft_page, can_manage: true))
      expect(page).to have_text("Draft")
      expect(page).to have_button("Publish")
    end

    it "shows no Publish button on a published page" do
      render_inline(build_component(can_manage: true))
      expect(page).to have_no_button("Publish")
    end

    it "shows no Publish button to a non-GM even on a draft page" do
      render_inline(build_component(page_record: draft_page, can_manage: false))
      expect(page).to have_no_button("Publish")
    end
  end

  describe "title" do
    it "renders the page title as a heading" do
      render_inline(build_component)
      expect(page).to have_css("h1", text: "Lore")
    end
  end

  describe "empty state" do
    it "shows a placeholder when there is no body" do
      render_inline(build_component(page_record: build_stubbed(:page, game: game, body: nil)))
      expect(page).to have_text("no content yet")
    end
  end
end
