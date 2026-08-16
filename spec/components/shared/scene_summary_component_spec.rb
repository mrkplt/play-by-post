require "rails_helper"

RSpec.describe Shared::SceneSummaryComponent, type: :component do
  let(:game) { build_stubbed(:game) }
  let(:scene) { build_stubbed(:scene, game: game) }
  let(:summary) { build_stubbed(:scene_summary, scene: scene, body: "A tale of **glory**.") }

  def presenter_for(summary_record: summary, can_manage:)
    policy = instance_double(SceneSummaryPolicy, manage?: can_manage)
    urls = double("urls",
      edit_game_scene_scene_summary_path: "/edit",
      game_scene_scene_summary_path: "/summary",
      publish_game_scene_scene_summary_path: "/summary/publish")
    SceneSummaryPresenter.new(summary_record, game: game, urls: urls, policy: policy)
  end

  def rendered(summary_record: summary, can_manage: false)
    render_inline(described_class.new(summary: presenter_for(summary_record: summary_record, can_manage: can_manage)))
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

  context "draft affordances" do
    let(:draft_summary) { build_stubbed(:scene_summary, scene: scene, draft: true) }

    it "shows a Draft badge and Publish button to the GM on a draft summary" do
      result = rendered(summary_record: draft_summary, can_manage: true)
      expect(result).to have_text("Draft")
      expect(result).to have_button("Publish")
    end

    it "shows no Publish button on a published summary" do
      expect(rendered(can_manage: true)).to have_no_button("Publish")
    end

    it "shows no Publish button to a non-GM even on a draft summary" do
      expect(rendered(summary_record: draft_summary, can_manage: false)).to have_no_button("Publish")
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
