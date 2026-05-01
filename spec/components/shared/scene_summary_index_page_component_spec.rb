require "rails_helper"

RSpec.describe Shared::SceneSummaryIndexPageComponent, type: :component do
  let(:game) { build_stubbed(:game, name: "Myth Quest") }
  let(:pagy) { double("Pagy", series_nav: "") }

  context "when summaries is empty" do
    subject(:component) { described_class.new(game: game, summaries: [], pagy: pagy, is_gm: false) }

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
      described_class.new(game: game, summaries: [summary], pagy: pagy, is_gm: false)
    end

    it "summaries_empty? returns false" do
      expect(component.summaries_empty?).to be(false)
    end

    it "renders scene summary entries" do
      render_inline(component)
      expect(page).to have_text(scene.title)
    end
  end

  context "when is_gm is true" do
    it "is_gm? returns true" do
      component = described_class.new(game: game, summaries: [], pagy: pagy, is_gm: true)
      expect(component.is_gm?).to be(true)
    end

    it "renders the Edit Game link" do
      render_inline(described_class.new(game: game, summaries: [], pagy: pagy, is_gm: true))
      expect(page).to have_link("Edit Game")
    end
  end

  context "when is_gm is false" do
    it "is_gm? returns false" do
      component = described_class.new(game: game, summaries: [], pagy: pagy, is_gm: false)
      expect(component.is_gm?).to be(false)
    end

    it "does not render the Edit Game link" do
      render_inline(described_class.new(game: game, summaries: [], pagy: pagy, is_gm: false))
      expect(page).not_to have_link("Edit Game")
    end
  end
end
