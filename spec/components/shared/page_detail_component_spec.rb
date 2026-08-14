require "rails_helper"

RSpec.describe Shared::PageDetailComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:game_presenter) { GamePresenter.new(game, policy: instance_double(GamePolicy)) }
  let(:page_record) { present(build_stubbed(:page, game: game, title: "Lore", slug: "abc123def456ghij", body: "# Heading\n\nBody text.")) }

  def present(page)
    PagePresenter.new(page, game_policy: instance_double(GamePolicy), page_policy: instance_double(PagePolicy))
  end

  def build_component(**overrides)
    described_class.new(**{ game: game_presenter, page: page_record, can_manage: false }.merge(overrides))
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

  describe "title" do
    it "renders the page title as a heading" do
      render_inline(build_component)
      expect(page).to have_css("h1", text: "Lore")
    end
  end

  describe "empty state" do
    it "shows a placeholder when there is no body" do
      render_inline(build_component(page: present(build_stubbed(:page, game: game, body: nil))))
      expect(page).to have_text("no content yet")
    end
  end
end
