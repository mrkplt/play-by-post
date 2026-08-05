# typed: false

require "rails_helper"

RSpec.describe Shared::SceneResolveFormComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:scene) { build_stubbed(:scene, game: game) }

  subject(:component) { described_class.new(game: game, scene: scene) }

  # The form lives inside the `hidden` #resolve-form wrapper, so its contents
  # are inspected with visible: :all.
  describe "rendering" do
    before { render_inline(component) }

    it "posts to the scene's resolve route" do
      expect(page).to have_css(
        "form[action='/games/#{game.id}/scenes/#{scene.id}/resolve']", visible: :all
      )
    end

    it "keeps the End Scene toggle target and confirm button" do
      expect(page).to have_css("#resolve-form[hidden]", visible: :all)
      expect(page).to have_button("Confirm — End Scene", visible: :all)
    end

    it "wires the outcome field to the markdown toolbar and live preview" do
      form = page.find("#resolve-form form", visible: :all)
      expect(form["data-controller"]).to include("markdown-preview", "markdown-toolbar")
      expect(page).to have_css("textarea.markdown-editor[data-markdown-preview-target='input']", visible: :all)
      expect(page).to have_css("[role='toolbar'][aria-label='Markdown formatting']", visible: :all)
      expect(page).to have_css("[data-markdown-preview-target='preview']", visible: :all)
    end
  end
end
