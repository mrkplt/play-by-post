require "rails_helper"

RSpec.describe Shared::NotebookFormComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:game_presenter) { GamePresenter.new(game, policy: instance_double(GamePolicy)) }
  let(:new_entry) { NotebookEntryPresenter.new(game.notebook_entries.new) }
  let(:existing_entry) do
    NotebookEntryPresenter.new(build_stubbed(:notebook_entry, game: game, title: "Idea", slug: "abc123def456ghij"))
  end

  def build_component(notebook_entry:)
    described_class.new(game: game_presenter, notebook_entry: notebook_entry)
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

  describe "back_href" do
    it "points a new entry's back_href at the notebook index" do
      component = build_component(notebook_entry: new_entry)
      render_inline(component)
      expect(component.back_href).to eq(path(:game_notebook_entries_path, game))
    end

    it "points an edit's back_href at the board — there is no read screen" do
      component = build_component(notebook_entry: existing_entry)
      render_inline(component)
      expect(component.back_href).to eq(path(:game_notebook_entries_path, game))
    end
  end

  describe "form_id" do
    it "gives the new form a stable id for the external submit button" do
      render_inline(build_component(notebook_entry: new_entry))
      expect(page).to have_css("form#notebook_entry_new_form_element")
    end

    it "scopes the edit form id to the record, avoiding the dom_id(entry) Turbo Stream target" do
      render_inline(build_component(notebook_entry: existing_entry))
      expect(page).to have_css("form#notebook_entry_#{existing_entry.id}_edit_form_element")
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
