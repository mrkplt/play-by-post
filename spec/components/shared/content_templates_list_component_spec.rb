require "rails_helper"

RSpec.describe Shared::ContentTemplatesListComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:urls) { Rails.application.routes.url_helpers }
  let(:game_presenter) { GamePresenter.new(game, policy: instance_double(GamePolicy, manage?: true), urls: urls) }

  def template_presenter(content_type:)
    template = build_stubbed(:content_template, game: game, content_type: content_type)
    ContentTemplatePresenter.new(template, game: game, urls: urls)
  end

  def build_component(templates)
    described_class.new(game: game_presenter, templates: templates)
  end

  describe "#can_add?" do
    it "is true while some content type has no template" do
      expect(build_component([ template_presenter(content_type: "page") ]).can_add?).to be(true)
    end

    it "is false once every content type has a template" do
      full = ContentTemplate::CONTENT_TYPES.map { |type| template_presenter(content_type: type) }
      expect(build_component(full).can_add?).to be(false)
    end
  end

  describe "#rows" do
    it "builds a titled row per template linking to its edit screen with actions" do
      rows = build_component([ template_presenter(content_type: "page") ]).rows

      expect(rows.size).to eq(1)
      expect(rows.first[:title]).to eq("Page")
      expect(rows.first[:controls]).to be_a(Shared::TemplateRowActionsComponent)
    end
  end

  describe "rendering" do
    it "renders a row per template with Edit and Delete, and a New Template action" do
      render_inline(build_component([ template_presenter(content_type: "page") ]))
      expect(page).to have_text("Page")
      expect(page).to have_link("Edit")
      expect(page).to have_button("Delete")
      expect(page).to have_link("New Template")
    end

    it "shows no New Template action when every type is templated" do
      full = ContentTemplate::CONTENT_TYPES.map { |type| template_presenter(content_type: type) }
      render_inline(build_component(full))
      expect(page).to have_no_link("New Template")
    end

    it "shows the empty state when there are no templates" do
      render_inline(build_component([]))
      expect(page).to have_text("No templates yet.")
    end
  end
end
