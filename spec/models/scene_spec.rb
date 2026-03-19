require "rails_helper"

RSpec.describe Scene, type: :model do
  describe "validations" do
    it "requires a title" do
      expect(build(:scene, title: nil)).not_to be_valid
    end

    it "enforces max title length of 200" do
      expect(build(:scene, title: "a" * 201)).not_to be_valid
    end

    it "is valid with required attributes" do
      expect(build(:scene)).to be_valid
    end
  end

  describe "#resolved?" do
    it "returns false when resolved_at is nil" do
      expect(build(:scene).resolved?).to be false
    end

    it "returns true when resolved_at is set" do
      expect(build(:scene, :resolved).resolved?).to be true
    end
  end

  describe "#participant?" do
    let(:scene) { create(:scene) }
    let(:user) { create(:user) }

    it "returns true when user is a participant" do
      scene.scene_participants.create!(user: user)
      expect(scene.participant?(user)).to be true
    end

    it "returns false when user is not a participant" do
      expect(scene.participant?(user)).to be false
    end
  end

  describe "scopes" do
    it ".active returns scenes without resolved_at" do
      active = create(:scene)
      create(:scene, :resolved)
      expect(Scene.active).to contain_exactly(active)
    end

    it ".resolved returns scenes with resolved_at" do
      resolved = create(:scene, :resolved)
      create(:scene)
      expect(Scene.resolved).to contain_exactly(resolved)
    end
  end
end
