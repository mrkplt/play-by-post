require "rails_helper"

RSpec.describe Shared::SceneSummaryComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:scene) { build_stubbed(:scene, game: game) }
  let(:summary) { build_stubbed(:scene_summary, scene: scene, body: "A tale of **glory**.") }

  def presenter_for(can_manage:)
    policy = instance_double(SceneSummaryPolicy, manage?: can_manage)
    urls = double("urls", edit_game_scene_scene_summary_path: "/edit", game_scene_scene_summary_path: "/summary")
    SceneSummaryPresenter.new(summary, game: game, urls: urls, policy: policy)
  end

  def rendered(can_manage: false)
    render_inline(described_class.new(summary: presenter_for(can_manage: can_manage)))
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
      expect(rendered(can_manage: true)).to have_text("Edit")
      expect(rendered(can_manage: true)).to have_button("Delete")
    end
  end

  context "when not GM" do
    it "hides edit and delete controls" do
      expect(rendered(can_manage: false)).not_to have_text("Edit")
      expect(rendered(can_manage: false)).not_to have_button("Delete")
    end
  end

  context "with a hand-written summary" do
    it "status_badge_variant returns 'gray'" do
      component = described_class.new(summary: presenter_for(can_manage: false))
      expect(component.status_badge_variant).to eq("gray")
    end
  end

  context "when AI-generated" do
    let(:summary) { build_stubbed(:scene_summary, :ai_generated, scene: scene) }

    it "shows AI-generated badge" do
      expect(rendered).to have_text("AI-generated")
    end

    it "status_badge_variant returns 'blue'" do
      component = described_class.new(summary: presenter_for(can_manage: false))
      expect(component.status_badge_variant).to eq("blue")
    end
  end

  context "when AI-generated and edited" do
    let(:summary) { build_stubbed(:scene_summary, :ai_generated, :edited, scene: scene) }

    it "shows Edited badge" do
      expect(rendered).to have_text("Edited")
    end

    it "status_badge_variant returns 'yellow'" do
      component = described_class.new(summary: presenter_for(can_manage: false))
      expect(component.status_badge_variant).to eq("yellow")
    end
  end
end
