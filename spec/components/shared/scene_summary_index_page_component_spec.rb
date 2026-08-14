require "rails_helper"

RSpec.describe Shared::SceneSummaryIndexPageComponent, type: :component do
  let(:game) { build_stubbed(:game, name: "Myth Quest") }
  let(:pagy) { double("Pagy", series_nav: "") }
  let(:urls) { double("urls", game_scene_path: "/games/1/scenes/2") }

  def collection_presenter_for(summaries)
    SceneSummaryCollectionPresenter.new(summaries, game: game, urls: urls, pagy: pagy)
  end

  context "when summaries is empty" do
    subject(:component) { described_class.new(summaries: collection_presenter_for([])) }

    it "summaries_empty? returns true" do
      expect(component.summaries_empty?).to be(true)
    end

    it "renders the empty state message" do
      render_inline(component)
      expect(page).to have_text("No summaries yet")
    end
  end

  context "when summaries are present" do
    let(:scene) { build_stubbed(:scene, game: game, resolved_at: Time.zone.now) }
    let(:summary) { build_stubbed(:scene_summary, scene: scene) }

    subject(:component) do
      described_class.new(summaries: collection_presenter_for([ summary ]))
    end

    it "summaries_empty? returns false" do
      expect(component.summaries_empty?).to be(false)
    end

    it "renders scene summary entries" do
      render_inline(component)
      expect(page).to have_text(scene.title)
    end
  end
end
