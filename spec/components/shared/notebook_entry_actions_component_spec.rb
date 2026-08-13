require "rails_helper"

RSpec.describe Shared::NotebookEntryActionsComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:entry) { build_stubbed(:notebook_entry, game: game, title: "Idea", slug: "abc123def456ghij") }

  def routes
    Rails.application.routes.url_helpers
  end

  def promoted_entry
    promoted_page = build_stubbed(:page, game: game, title: "The Sunken Temple", slug: "temple0000000000")
    build_stubbed(:notebook_entry, game: game, title: "Idea", slug: "promotedslug1234",
                  promoted_page: promoted_page)
  end

  def build_component(**overrides)
    described_class.new(**{ game: game, notebook_entry: entry }.merge(overrides))
  end

  describe "rendering" do
    it "offers the lane picker so a GM can move without returning to the board" do
      render_inline(build_component)
      expect(page).to have_css("select[name='notebook_entry[status]']")
    end

    it "offers Promote for an entry that has not been promoted" do
      render_inline(build_component)
      expect(page).to have_button("Promote")
    end

    it "targets the promote route" do
      render_inline(build_component)
      expect(page).to have_css("form[action='#{routes.promote_game_notebook_entry_path(game, entry)}']")
    end

    it "offers Delete" do
      render_inline(build_component)
      expect(page).to have_button("Delete")
    end

    it "targets the entry's destroy route from Delete" do
      render_inline(build_component)
      form = page.find("form[action='#{routes.game_notebook_entry_path(game, entry)}']")
      expect(form).to have_field("_method", type: :hidden, with: "delete")
    end

    it "guards Delete with an are-you-sure confirmation" do
      render_inline(build_component)
      expect(page).to have_css("form[data-turbo-confirm='#{described_class::CONFIRM}']")
    end

    it "warns that deletion cannot be undone" do
      expect(build_component.confirm).to include("cannot be undone")
    end
  end

  describe "once promoted" do
    it "replaces Promote with a link to the page, so a page is never created twice" do
      promoted = promoted_entry
      render_inline(build_component(notebook_entry: promoted))

      expect(page).to have_no_button("Promote")
      expect(page).to have_link(
        "Promoted to: The Sunken Temple",
        href: routes.game_page_path(game, T.must(promoted.promoted_page))
      )
    end

    it "still offers Delete and the lane picker" do
      render_inline(build_component(notebook_entry: promoted_entry))
      expect(page).to have_button("Delete")
      expect(page).to have_css("select[name='notebook_entry[status]']")
    end

    it "names the page the entry became" do
      expect(build_component(notebook_entry: promoted_entry).promoted_label)
        .to eq("Promoted to: The Sunken Temple")
    end
  end

  describe "#promoted?" do
    it "is false for a fresh entry" do
      expect(build_component.promoted?).to be(false)
    end

    it "is true once the entry has a page" do
      expect(build_component(notebook_entry: promoted_entry).promoted?).to be(true)
    end
  end
end
