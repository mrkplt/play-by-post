require "rails_helper"

RSpec.describe SceneReadState do
  let(:game) { create(:game) }
  let(:scene) { create(:scene, game: game) }
  let(:user) { create(:user) }

  describe ".eligible_ids" do
    it "includes a post just inside the window" do
      post = build_stubbed(:post, id: 1, created_at: (described_class::WINDOW - 1.second).ago)
      expect(described_class.eligible_ids([ post ])).to eq([ 1 ])
    end

    it "excludes a post exactly at the window boundary" do
      post = build_stubbed(:post, id: 2, created_at: described_class::WINDOW.ago)
      expect(described_class.eligible_ids([ post ])).to eq([])
    end

    it "excludes a post older than the window" do
      post = build_stubbed(:post, id: 3, created_at: (described_class::WINDOW + 1.hour).ago)
      expect(described_class.eligible_ids([ post ])).to eq([])
    end

    it "returns ids, not the posts themselves" do
      post = build_stubbed(:post, id: 42, created_at: 1.minute.ago)
      expect(described_class.eligible_ids([ post ])).to eq([ 42 ])
    end
  end

  describe ".for" do
    it "is empty for a resolved scene, without querying reads" do
      resolved = create(:scene, :resolved, game: game)
      post = create(:post, scene: resolved, user: user, created_at: 1.hour.ago)
      create(:post_read, post: post, user: user)

      expect(described_class.for(scene: resolved, posts: [ post ], user: user)).to eq(Set.new)
    end

    it "includes a recent post the user has read" do
      post = create(:post, scene: scene, user: user, created_at: 1.hour.ago)
      create(:post_read, post: post, user: user)

      expect(described_class.for(scene: scene, posts: [ post ], user: user)).to eq(Set[post.id])
    end

    it "excludes a recent post the user has not read" do
      post = create(:post, scene: scene, user: user, created_at: 1.hour.ago)

      expect(described_class.for(scene: scene, posts: [ post ], user: user)).to eq(Set.new)
    end

    # Scoping by user: another person's read must not count as this user's.
    it "ignores a read belonging to a different user" do
      other = create(:user)
      post = create(:post, scene: scene, user: user, created_at: 1.hour.ago)
      create(:post_read, post: post, user: other)

      expect(described_class.for(scene: scene, posts: [ post ], user: user)).to eq(Set.new)
    end

    # Scoping by post: a read for a post outside the supplied set must not leak in.
    it "ignores a read for a post that is not among the supplied posts" do
      shown = create(:post, scene: scene, user: user, created_at: 1.hour.ago)
      elsewhere = create(:post, scene: scene, user: user, created_at: 1.hour.ago)
      create(:post_read, post: elsewhere, user: user)

      expect(described_class.for(scene: scene, posts: [ shown ], user: user)).to eq(Set.new)
    end

    it "ignores a read for a post older than the window" do
      stale = create(:post, scene: scene, user: user, created_at: (described_class::WINDOW + 1.hour).ago)
      create(:post_read, post: stale, user: user)

      expect(described_class.for(scene: scene, posts: [ stale ], user: user)).to eq(Set.new)
    end
  end
end
