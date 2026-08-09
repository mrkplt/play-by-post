require "rails_helper"

RSpec.describe Shared::NotebookFormComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:new_entry) { game.notebook_entries.new }
  let(:existing_entry) { build_stubbed(:notebook_entry, game: game, title: "Idea", slug: "abc123def456ghij") }

  def build_component(notebook_entry:)
    described_class.new(game: game, notebook_entry: notebook_entry)
  end

  def path(name, *args)
    Rails.application.routes.url_helpers.public_send(name, *args)
  end

  describe "mode derived from the entry" do
    it "treats an unpersisted entry as a new record" do
      component = build_component(notebook_entry: new_entry)
      expect(component.new_record?).to be(true)
      expect(component.submit_label).to eq("Create Entry")
    end

    it "treats a persisted entry as an edit" do
      component = build_component(notebook_entry: existing_entry)
      expect(component.new_record?).to be(false)
      expect(component.submit_label).to eq("Save")
    end
  end

  describe "cancel link (back_href)" do
    it "points a new entry's cancel at the notebook index" do
      render_inline(build_component(notebook_entry: new_entry))
      expect(page).to have_link("Cancel", href: path(:game_notebook_entries_path, game))
    end

    it "points an edit's cancel at the entry itself" do
      render_inline(build_component(notebook_entry: existing_entry))
      expect(page).to have_link("Cancel", href: path(:game_notebook_entry_path, game, existing_entry))
    end
  end

  describe "error surfacing" do
    it "reports no errors on a clean entry" do
      expect(build_component(notebook_entry: existing_entry).errors?).to be(false)
    end

    it "surfaces validation messages" do
      new_entry.valid?
      new_entry.errors.add(:title, "can't be blank")
      component = build_component(notebook_entry: new_entry)
      expect(component.errors?).to be(true)
      expect(component.error_messages).to include("Title can't be blank")
    end
  end

  describe "rendering" do
    it "renders a title field and a markdown body editor" do
      render_inline(build_component(notebook_entry: new_entry))
      expect(page).to have_field("notebook_entry[title]")
      expect(page).to have_css("textarea.markdown-editor[name='notebook_entry[body]']")
    end
  end
end
