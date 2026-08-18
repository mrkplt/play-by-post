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

  # Both branches read through #posts, so stubbing that association covers the
  # loaded and unloaded paths without persisting a scene or any posts.
  describe "#last_activity_at" do
    let(:scene) { build_stubbed(:scene) }

    def with_posts(posts)
      allow(scene).to receive(:posts).and_return(posts)
      scene.last_activity_at
    end

    it "returns created_at when there are no posts" do
      expect(with_posts(double(loaded?: false, maximum: nil))).to eq(scene.created_at)
    end

    it "returns the most recent post created_at" do
      latest = 1.hour.ago
      expect(with_posts(double(loaded?: false, maximum: latest))).to eq(latest)
    end

    it "uses in-memory posts when loaded" do
      latest = 1.hour.ago

      expect(with_posts(double(loaded?: true, map: [ 3.hours.ago, latest ]))).to eq(latest)
    end

    it "falls back to created_at when loaded posts are empty" do
      expect(with_posts(double(loaded?: true, map: []))).to eq(scene.created_at)
    end
  end

  describe "#participant?" do
    let(:scene) { build_stubbed(:scene) }
    let(:user) { build_stubbed(:user) }

    def membership(exists)
      participants = double
      allow(participants).to receive(:exists?).with(user: user).and_return(exists)
      allow(scene).to receive(:scene_participants).and_return(participants)
      scene.participant?(user)
    end

    it "returns true when user is a participant" do
      expect(membership(true)).to be true
    end

    it "returns false when user is not a participant" do
      expect(membership(false)).to be false
    end
  end

  describe "scopes" do
    it ".active selects rows with a null resolved_at" do
      expect(unquoted_sql(Scene.active)).to include("scenes.resolved_at IS NULL")
    end

    it ".resolved selects rows with a non-null resolved_at" do
      expect(unquoted_sql(Scene.resolved)).to include("scenes.resolved_at IS NOT NULL")
    end
  end

  describe "associations" do
    it "has many child_scenes keyed by parent_scene_id" do
      association = Scene.reflect_on_association(:child_scenes)

      expect(association.macro).to eq(:has_many)
      expect(association.foreign_key).to eq("parent_scene_id")
    end

    it "belongs to a parent_scene optionally" do
      parent = create(:scene)
      child = create(:scene, parent_scene: parent, game: parent.game)
      expect(child.parent_scene).to eq(parent)
    end

    it "nullifies child parent_scene_id when the parent is destroyed" do
      expect(Scene.reflect_on_association(:child_scenes).options[:dependent]).to eq(:nullify)
    end
  end
end
