require "rails_helper"

# One detail component serves every versioned record; exercise it with both a
# page version and a notebook-entry version presenter to prove the shared
# interface it renders (title, body, editor, timestamp) holds for each.
RSpec.describe Shared::VersionDetailComponent, type: :component do
  let(:editor) { build_stubbed(:user) }

  shared_examples "a version detail view" do
    it "renders the version's title and body" do
      render_inline(described_class.new(version: presenter_for(title: "Ancient Lore", body: "# Once\n\nupon a time")))
      expect(page).to have_css("h1", text: "Ancient Lore")
      expect(page).to have_text("upon a time")
    end

    it "shows the editor and timestamp" do
      render_inline(described_class.new(version: presenter_for(title: "Lore", body: "x")))
      expect(page).to have_text("Edited by:")
      expect(page).to have_css("time")
    end

    it "shows a placeholder when the version has no body" do
      render_inline(described_class.new(version: presenter_for(title: "Lore", body: nil)))
      expect(page).to have_text("No content in this version.")
    end
  end

  context "with a page version" do
    def presenter_for(title:, body:)
      version = build_stubbed(:page_version, edited_by: editor, title: title, body: body,
                                             created_at: Time.utc(2026, 1, 2, 15, 4))
      PageVersionPresenter.new(version)
    end

    it_behaves_like "a version detail view"
  end

  context "with a notebook-entry version" do
    def presenter_for(title:, body:)
      version = build_stubbed(:notebook_entry_version, edited_by: editor, title: title, body: body,
                                                       created_at: Time.utc(2026, 1, 2, 15, 4))
      NotebookEntryVersionPresenter.new(version)
    end

    it_behaves_like "a version detail view"
  end
end
