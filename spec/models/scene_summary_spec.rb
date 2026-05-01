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
