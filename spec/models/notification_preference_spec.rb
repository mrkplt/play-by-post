require "rails_helper"

RSpec.describe NotificationPreference, type: :model do
  let(:scene) { create(:scene) }
  let(:user) { create(:user) }

  describe ".muted?" do
    it "returns true when a muted preference exists" do
      allow(described_class).to receive(:exists?)
        .with(scene: scene, user: user, muted: true).and_return(true)

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
      existing = build(:notification_preference, scene: scene, user: user, muted: true)
      allow(described_class).to receive(:find_or_initialize_by).and_return(existing)
      allow(existing).to receive(:save!)

      expect(described_class.toggle!(scene, user).muted).to be false
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

    it "writes the toggled preference" do
      pref = build(:notification_preference, scene: scene, user: user, muted: false)
      allow(described_class).to receive(:find_or_initialize_by).and_return(pref)
      allow(pref).to receive(:save!)

      described_class.toggle!(scene, user)

      expect(pref).to have_received(:save!)
    end

    it "reuses the existing record rather than adding one" do
      allow(described_class).to receive(:find_or_initialize_by)
        .and_return(build(:notification_preference, scene: scene, user: user, muted: false))

      described_class.toggle!(scene, user)

      expect(described_class).to have_received(:find_or_initialize_by).with(scene: scene, user: user)
    end
  end
end
