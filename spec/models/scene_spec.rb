require "rails_helper"

RSpec.describe Scene, type: :model do
  describe "validations" do
    it "is valid with required attributes" do
      expect(build(:scene)).to be_valid
    end

    it "enforces max title length of 200" do
      expect(build(:scene, title: "a" * 201)).not_to be_valid
    end
  end

  describe "image validation" do
    it "accepts a valid image" do
      scene = build(:scene)
      scene.image.attach(io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
                         filename: "test.png", content_type: "image/png")
      expect(scene).to be_valid
    end

    it "rejects an image over 10MB" do
      scene = build(:scene)
      scene.image.attach(io: StringIO.new("x" * (11 * 1024 * 1024)),
                         filename: "big.png", content_type: "image/png")
      expect(scene).not_to be_valid
      expect(scene.errors[:image]).to include("must be less than 10MB")
    end

    it "allows an image exactly 10MB" do
      scene = build(:scene)
      scene.image.attach(io: StringIO.new("x" * 10.megabytes),
                         filename: "exact.png", content_type: "image/png")
      expect(scene).to be_valid
    end

    it "rejects a non-image content type" do
      scene = build(:scene)
      scene.image.attach(io: StringIO.new("test"),
                         filename: "doc.pdf", content_type: "application/pdf")
      expect(scene).not_to be_valid
      expect(scene.errors[:image]).to include("must be a JPEG, PNG, GIF, or WebP image")
    end
  end

  describe "default title" do
    it "sets a datetime stamp when title is blank" do
      scene = build(:scene, title: nil)
      scene.valid?
      expect(scene.title).to match(/\A\w+ \d+, \d{4} \d+:\d+ [AP]M\z/)
    end

    it "sets a datetime stamp when title is empty string" do
      scene = build(:scene, title: "")
      scene.valid?
      expect(scene.title).to match(/\A\w+ \d+, \d{4} \d+:\d+ [AP]M\z/)
    end

    it "preserves an explicit title" do
      scene = build(:scene, title: "The Tavern")
      scene.valid?
      expect(scene.title).to eq("The Tavern")
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

  describe "#last_activity_at" do
    let(:scene) { create(:scene) }

    it "returns created_at when there are no posts" do
      expect(scene.last_activity_at).to eq(scene.created_at)
    end

    it "returns the most recent post created_at" do
      create(:post, scene: scene, created_at: 2.hours.ago)
      latest = create(:post, scene: scene, created_at: 1.hour.ago)
      expect(scene.last_activity_at).to eq(latest.created_at)
    end

    it "uses in-memory posts when loaded" do
      create(:post, scene: scene, created_at: 1.hour.ago)
      loaded_scene = Scene.includes(:posts).find(scene.id)
      expect(loaded_scene.last_activity_at).to eq(loaded_scene.posts.first.created_at)
    end
  end

  describe "#participant?" do
    let(:scene) { create(:scene) }
    let(:user) { create(:user) }

    it "returns true when user is a participant" do
      scene.scene_participants.create!(user: user)
      expect(scene.participant?(user)).to be true
    end

    it "returns false when user is not a participant but others are" do
      other_user = create(:user)
      scene.scene_participants.create!(user: other_user)
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

  describe "associations" do
    it "has many child_scenes" do
      parent = create(:scene)
      child1 = create(:scene, parent_scene: parent, game: parent.game)
      child2 = create(:scene, parent_scene: parent, game: parent.game)
      expect(parent.child_scenes).to contain_exactly(child1, child2)
    end

    it "belongs to a parent_scene optionally" do
      parent = create(:scene)
      child = create(:scene, parent_scene: parent, game: parent.game)
      expect(child.parent_scene).to eq(parent)
    end

    it "nullifies child parent_scene_id when parent is destroyed" do
      parent = create(:scene)
      child = create(:scene, parent_scene: parent, game: parent.game)
      parent.destroy
      expect(child.reload.parent_scene_id).to be_nil
    end
  end
end
