require "rails_helper"

RSpec.describe SceneSummary, type: :model do
  describe "associations" do
    it "belongs to scene" do
      scene = create(:scene)
      summary = create(:scene_summary, scene: scene)
      expect(summary.scene).to eq(scene)
    end

    it "belongs to edited_by (optional)" do
      summary = build(:scene_summary, edited_by: nil)
      expect(summary).to be_valid
    end
  end

  describe "validations" do
    it "is valid with required attributes" do
      expect(build(:scene_summary)).to be_valid
    end

    it "requires body" do
      expect(build(:scene_summary, body: "")).not_to be_valid
    end
  end

  describe ".public_for_game" do
    let(:game) { create(:game) }

    it "includes summaries of public resolved scenes", :db do
      scene = create(:scene, :resolved, game: game, private: false)
      summary = create(:scene_summary, scene: scene)
      expect(described_class.public_for_game(game)).to include(summary)
    end

    it "excludes summaries of private scenes", :db do
      scene = create(:scene, :resolved, game: game, private: true)
      summary = create(:scene_summary, scene: scene)
      expect(described_class.public_for_game(game)).not_to include(summary)
    end

    it "excludes summaries of unresolved scenes", :db do
      scene = create(:scene, game: game, private: false)
      summary = create(:scene_summary, scene: scene)
      expect(described_class.public_for_game(game)).not_to include(summary)
    end

    it "excludes summaries from other games", :db do
      other_scene = create(:scene, :resolved, private: false)
      summary = create(:scene_summary, scene: other_scene)
      expect(described_class.public_for_game(game)).not_to include(summary)
    end

    it "orders by scene resolved_at descending", :db do
      older = create(:scene, :resolved, game: game, private: false, resolved_at: 2.days.ago)
      newer = create(:scene, :resolved, game: game, private: false, resolved_at: 1.day.ago)
      older_summary = create(:scene_summary, scene: older)
      newer_summary = create(:scene_summary, scene: newer)
      expect(described_class.public_for_game(game).to_a).to eq([ newer_summary, older_summary ])
    end
  end

  describe "#ai_generated?" do
    it "returns true when generated_at is present" do
      expect(build(:scene_summary, :ai_generated).ai_generated?).to be true
    end

    it "returns false when generated_at is nil" do
      expect(build(:scene_summary).ai_generated?).to be false
    end
  end

  describe "#edited?" do
    it "returns true when edited_at is present" do
      expect(build(:scene_summary, :edited).edited?).to be true
    end

    it "returns false when edited_at is nil" do
      expect(build(:scene_summary).edited?).to be false
    end
  end
end
