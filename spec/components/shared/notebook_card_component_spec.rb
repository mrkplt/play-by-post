require "rails_helper"

RSpec.describe Shared::NotebookCardComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:entry) { build_stubbed(:notebook_entry, game: game, title: "Idea", slug: "abc123def456ghij", body: "Some **markdown** body.") }

  def build_component(**overrides)
    described_class.new(**{ game: game, notebook_entry: entry, mode: :read }.merge(overrides))
  end

  describe "#status_options" do
    it "includes every status with a human label" do
      labels = build_component.status_options
      expect(labels).to eq([ [ "New", "new" ], [ "Expand", "expand" ], [ "Done", "done" ], [ "Discard", "discard" ] ])
    end
  end

  describe "#excerpt" do
    it "renders short bodies in full" do
      short = build_stubbed(:notebook_entry, game: game, body: "short body")
      expect(build_component(notebook_entry: short).excerpt).to include("short body")
    end

    it "truncates long bodies" do
      long = build_stubbed(:notebook_entry, game: game, body: "a" * 500)
      excerpt = build_component(notebook_entry: long).excerpt
      expect(excerpt).to include("…")
    end
  end

  describe "read mode" do
    it "renders the title, excerpt, lane select, and GM actions" do
      render_inline(build_component)

      expect(page).to have_text("Idea")
      expect(page).to have_css("select[name='notebook_entry[status]']")
      expect(page).to have_link("Edit")
      expect(page).to have_button("Promote")
      expect(page).to have_button("Delete")
    end

    it "wraps the card in the entry's dom_id" do
      render_inline(build_component)
      expect(page).to have_css("##{ActionView::RecordIdentifier.dom_id(entry)}")
    end

    NotebookEntry::STATUSES.each_with_index do |status, i|
      it "selects the #{status.inspect} option when the entry is in that lane" do
        entry_in_status = build_stubbed(:notebook_entry, game: game, slug: "statusslug#{i}23456", status: status)
        render_inline(build_component(notebook_entry: entry_in_status))
        expect(page).to have_select("notebook_entry[status]", selected: described_class::STATUS_LABELS.fetch(status))
      end
    end

    it "shows Promoted to instead of Promote once promoted" do
      page_record = build_stubbed(:page, game: game, title: "Promoted Page", slug: "pagepageslug1234")
      promoted_entry = build_stubbed(:notebook_entry, game: game, slug: "promotedentry123", promoted_page: page_record)
      render_inline(build_component(notebook_entry: promoted_entry))

      expect(page).to have_no_button("Promote")
      expect(page).to have_link("Promoted to: Promoted Page")
    end

    it "shows an empty-body placeholder" do
      no_body = build_stubbed(:notebook_entry, game: game, slug: "nobodyslug1234567", body: nil)
      render_inline(build_component(notebook_entry: no_body))
      expect(page).to have_text("No content yet.")
    end
  end

  describe "edit mode" do
    it "renders an inline form with title input and markdown editor" do
      render_inline(build_component(mode: :edit))

      expect(page).to have_field("notebook_entry[title]")
      expect(page).to have_css("textarea.markdown-editor[name='notebook_entry[body]']")
      expect(page).to have_button("Save")
      expect(page).to have_link("Cancel")
    end
  end
end
