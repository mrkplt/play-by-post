require "rails_helper"

RSpec.describe Shared::SceneSummaryComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:scene) { build_stubbed(:scene, game: game) }
  let(:summary) { build_stubbed(:scene_summary, scene: scene, body: "A tale of **glory**.") }
  let(:presenter) { SceneSummaryPresenter.new(summary) }

  def rendered(is_gm: false)
    render_inline(described_class.new(summary: presenter, game: game, scene: scene, is_gm: is_gm))
    page
  end

  it "renders the summary body as markdown" do
    expect(rendered).to have_css("strong", text: "glory")
  end

  it "shows the Hand-written status badge for manual summaries" do
    expect(rendered).to have_text("Hand-written")
  end

  context "when GM" do
    it "shows edit and delete controls" do
      expect(rendered(is_gm: true)).to have_text("Edit")
      expect(rendered(is_gm: true)).to have_button("Delete")
    end
  end

  context "when not GM" do
    it "hides edit and delete controls" do
      expect(rendered(is_gm: false)).not_to have_text("Edit")
      expect(rendered(is_gm: false)).not_to have_button("Delete")
    end
  end

  context "with a hand-written summary" do
    it "status_badge_variant returns 'gray'" do
      component = described_class.new(summary: presenter, game: game, scene: scene, is_gm: false)
      expect(component.status_badge_variant).to eq("gray")
    end
  end

  context "when AI-generated" do
    let(:summary) { build_stubbed(:scene_summary, :ai_generated, scene: scene) }

    it "shows AI-generated badge" do
      expect(rendered).to have_text("AI-generated")
    end

    it "status_badge_variant returns 'blue'" do
      component = described_class.new(summary: presenter, game: game, scene: scene, is_gm: false)
      expect(component.status_badge_variant).to eq("blue")
    end
  end

  context "when AI-generated and edited" do
    let(:summary) { build_stubbed(:scene_summary, :ai_generated, :edited, scene: scene) }

    it "shows Edited badge" do
      expect(rendered).to have_text("Edited")
    end

    it "status_badge_variant returns 'yellow'" do
      component = described_class.new(summary: presenter, game: game, scene: scene, is_gm: false)
      expect(component.status_badge_variant).to eq("yellow")
    end
  end
end
