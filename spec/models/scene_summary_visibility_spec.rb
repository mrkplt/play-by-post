require "rails_helper"

# The single mapping that keeps "show the summary on the page" and "broadcast the
# summary to this stream" in agreement: a viewer's visibility class, and the set
# of classes a summary should reach.
RSpec.describe SceneSummaryVisibility, type: :model do
  let(:game) { create(:game) }
  let(:gm) { create(:user, :with_profile) }
  let(:player) { create(:user, :with_profile) }
  let(:scene) { create(:scene, :resolved, game: game) }

  before { create(:game_member, :game_master, game: game, user: gm) }

  describe ".for_viewer" do
    it "classes a GM as :manager, whatever their display preference" do
      gm.user_profile.update!(ai_display_preference: :hidden)

      expect(described_class.for_viewer(game: game, viewer: gm)).to eq(:manager)
    end

    it "classes a non-manager with a non-hidden preference as :plain" do
      create(:game_member, game: game, user: player)

      expect(described_class.for_viewer(game: game, viewer: player)).to eq(:plain)
    end

    it "classes a non-manager whose display preference is hidden as :hidden" do
      create(:game_member, game: game, user: player)
      player.user_profile.update!(ai_display_preference: :hidden)

      expect(described_class.for_viewer(game: game, viewer: player)).to eq(:hidden)
    end

    it "classes a nil viewer as :plain" do
      expect(described_class.for_viewer(game: game, viewer: nil)).to eq(:plain)
    end
  end

  describe ".classes_for" do
    it "broadcasts a draft only to managers" do
      summary = create(:scene_summary, scene: scene, draft: true, body: "")

      expect(described_class.classes_for(summary)).to eq([ :manager ])
    end

    it "broadcasts an AI-generated summary to managers and plain viewers, never hidden" do
      summary = create(:scene_summary, :ai_generated, scene: scene)

      expect(described_class.classes_for(summary)).to eq(%i[manager plain])
    end

    it "broadcasts a published non-AI summary to every class" do
      summary = create(:scene_summary, scene: scene, draft: false)

      expect(described_class.classes_for(summary)).to eq(%i[manager plain hidden])
    end
  end

  describe "agreement with SceneSummary#visible_to?" do
    it "a viewer sees the summary exactly when their class is one it is broadcast to" do
      player.user_profile.update!(ai_display_preference: :hidden)
      summary = create(:scene_summary, :ai_generated, scene: scene)

      create(:game_member, game: game, user: player)
      viewer_class = described_class.for_viewer(game: game, viewer: player)
      expect(described_class.classes_for(summary)).not_to include(viewer_class)
      expect(summary.visible_to?(player)).to be(false)
    end
  end
end
