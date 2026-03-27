require "rails_helper"

RSpec.describe NotificationPreference, type: :model do
  let(:scene) { create(:scene) }
  let(:user) { create(:user) }

  describe ".muted?" do
    it "returns true when user has muted the scene" do
      create(:notification_preference, scene: scene, user: user, muted: true)
      expect(described_class.muted?(scene, user)).to be true
    end

    it "returns false when no preference exists" do
      expect(described_class.muted?(scene, user)).to be false
    end

    it "returns false when preference exists but muted is false" do
      create(:notification_preference, scene: scene, user: user, muted: false)
      expect(described_class.muted?(scene, user)).to be false
    end

    it "scopes to the correct scene" do
      other_scene = create(:scene)
      create(:notification_preference, scene: other_scene, user: user, muted: true)
      expect(described_class.muted?(scene, user)).to be false
    end

    it "scopes to the correct user" do
      other_user = create(:user)
      create(:notification_preference, scene: scene, user: other_user, muted: true)
      expect(described_class.muted?(scene, user)).to be false
    end
  end

  describe ".toggle!" do
    it "creates a muted preference when none exists" do
      pref = described_class.toggle!(scene, user)
      expect(pref.muted).to be true
      expect(pref).to be_persisted
    end

    it "unmutes when already muted" do
      create(:notification_preference, scene: scene, user: user, muted: true)
      pref = described_class.toggle!(scene, user)
      expect(pref.muted).to be false
    end

    it "mutes when already unmuted" do
      create(:notification_preference, scene: scene, user: user, muted: false)
      pref = described_class.toggle!(scene, user)
      expect(pref.muted).to be true
    end

    it "returns the preference record" do
      pref = described_class.toggle!(scene, user)
      expect(pref).to be_a(NotificationPreference)
      expect(pref.scene).to eq(scene)
      expect(pref.user).to eq(user)
    end

    it "persists the change" do
      described_class.toggle!(scene, user)
      expect(described_class.find_by(scene: scene, user: user).muted).to be true
    end

    it "does not create duplicate records" do
      described_class.toggle!(scene, user)
      described_class.toggle!(scene, user)
      expect(described_class.where(scene: scene, user: user).count).to eq(1)
    end
  end
end
