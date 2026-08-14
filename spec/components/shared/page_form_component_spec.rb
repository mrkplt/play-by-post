require "rails_helper"

RSpec.describe Shared::PageFormComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:game_presenter) { GamePresenter.new(game, policy: instance_double(GamePolicy)) }
  let(:new_page) { present(game.pages.new) }
  let(:existing_page) { present(build_stubbed(:page, game: game, title: "Lore", slug: "abc123def456ghij")) }

  def present(page)
    PagePresenter.new(page, game_policy: instance_double(GamePolicy), page_policy: instance_double(PagePolicy))
  end

  def build_component(page:)
    described_class.new(game: game_presenter, page: page)
  end

  def path(name, *args)
    Rails.application.routes.url_helpers.public_send(name, *args)
  end

  describe "mode derived from the page" do
    it "treats an unpersisted page as a new record" do
      component = build_component(page: new_page)
      expect(component.new_record?).to be(true)
      expect(component.submit_label).to eq("Create Page")
    end

    it "treats a persisted page as an edit" do
      component = build_component(page: existing_page)
      expect(component.new_record?).to be(false)
      expect(component.submit_label).to eq("Save")
    end
  end

  describe "back_href" do
    it "points a new page's back_href at the game pages tab" do
      component = build_component(page: new_page)
      render_inline(component)
      expect(component.back_href).to eq(path(:game_path, game, anchor: "pages"))
    end

    it "points an edit's back_href at the page itself" do
      component = build_component(page: existing_page)
      render_inline(component)
      expect(component.back_href).to eq(path(:game_page_path, game, existing_page.to_model))
    end
  end

  describe "form_id" do
    it "gives new and edit forms distinct, stable ids for the external submit button" do
      render_inline(build_component(page: new_page))
      expect(page).to have_css("form#new_page_form")
    end

    it "scopes the edit form id to the record" do
      render_inline(build_component(page: existing_page))
      expect(page).to have_css("form#edit_page_#{existing_page.id}_form")
    end
  end

  describe "error surfacing" do
    it "reports no errors on a clean page" do
      expect(build_component(page: existing_page).errors?).to be(false)
    end

    it "surfaces validation messages" do
      new_page.valid?
      new_page.errors.add(:title, "can't be blank")
      component = build_component(page: new_page)
      expect(component.errors?).to be(true)
      expect(component.error_messages).to include("Title can't be blank")
    end
  end

  describe "rendering" do
    it "renders a title field and a markdown body editor" do
      render_inline(build_component(page: new_page))
      expect(page).to have_field("page[title]")
      expect(page).to have_css("textarea.markdown-editor[name='page[body]']")
    end
  end
end
