require "rails_helper"

RSpec.describe ScenePostsPresenter do
  let(:scene) { build(:scene, created_at: Time.zone.parse("2024-03-10 09:00:00")) }
  let(:scene_presenter) { ScenePresenter.new(scene) }
  let(:current_user) { build_stubbed(:user) }
  let(:game) { build_stubbed(:game) }
  let(:urls) { double("urls") }

  subject(:presenter) { described_class.new(scene_presenter, game: game, urls: urls, current_user: current_user) }

  describe "#can_post?" do
    it "is true when the post policy allows it and the scene is open" do
      post_policy = instance_double(PostPolicy, create?: true)
      presenter = described_class.new(scene_presenter, post_policy: post_policy)
      allow(scene).to receive(:resolved?).and_return(false)
      expect(presenter.can_post?).to be(true)
    end

    it "is false when the scene is resolved" do
      post_policy = instance_double(PostPolicy, create?: true)
      presenter = described_class.new(scene_presenter, post_policy: post_policy)
      allow(scene).to receive(:resolved?).and_return(true)
      expect(presenter.can_post?).to be(false)
    end

    it "is false when the post policy denies it" do
      post_policy = instance_double(PostPolicy, create?: false)
      presenter = described_class.new(scene_presenter, post_policy: post_policy)
      allow(scene).to receive(:resolved?).and_return(false)
      expect(presenter.can_post?).to be(false)
    end
  end

  describe "#recoverable_draft" do
    let(:draft) { PostPresenter.new(build_stubbed(:post, :draft, scene: scene)) }

    it "returns the draft presenter when the scene is resolved" do
      allow(scene).to receive(:resolved?).and_return(true)
      expect(presenter.recoverable_draft(draft)).to eq(draft)
    end

    it "is nil when the scene is not resolved, even with a draft present" do
      allow(scene).to receive(:resolved?).and_return(false)
      expect(presenter.recoverable_draft(draft)).to be_nil
    end

    it "is nil when there is no draft, even on a resolved scene" do
      allow(scene).to receive(:resolved?).and_return(true)
      expect(presenter.recoverable_draft(nil)).to be_nil
    end
  end

  describe "#draft" do
    it "returns the viewer's draft post in this scene, wrapped, if any" do
      draft = build_stubbed(:post, :draft)
      drafts_rel = double("drafts rel")
      allow(scene).to receive(:posts).and_return(double(drafts: drafts_rel))
      allow(drafts_rel).to receive(:find_by).with(user: current_user).and_return(draft)

      result = presenter.draft
      expect(result).to be_a(PostPresenter)
    end

    it "is nil when the viewer has no draft" do
      drafts_rel = double("drafts rel")
      allow(scene).to receive(:posts).and_return(double(drafts: drafts_rel))
      allow(drafts_rel).to receive(:find_by).with(user: current_user).and_return(nil)

      expect(presenter.draft).to be_nil
    end
  end

  describe "#new_post" do
    it "returns a blank post presenter for the composer" do
      expect(presenter.new_post).to be_a(PostPresenter)
    end
  end

  describe "#posts_empty? and #post_presenters" do
    it "reports empty and returns an empty array when the controller supplied none" do
      expect(presenter.posts_empty?).to be(true)
      expect(presenter.post_presenters).to eq([])
    end

    it "returns the controller-supplied post presenters unchanged" do
      post_presenter = PostPresenter.new(build_stubbed(:post))
      with_posts = described_class.new(
        scene_presenter, game: game, urls: urls, current_user: current_user, post_presenters: [ post_presenter ]
      )

      expect(with_posts.posts_empty?).to be(false)
      expect(with_posts.post_presenters).to eq([ post_presenter ])
    end
  end

  describe "#read_post_ids" do
    it "asks SceneReadState for the viewer's read post ids" do
      allow(scene).to receive_message_chain(:posts, :published, :includes, :order, :to_a).and_return([])
      allow(SceneReadState).to receive(:for).and_return(Set.new([ 1, 2 ]))

      expect(presenter.read_post_ids).to eq(Set.new([ 1, 2 ]))
    end
  end

  describe "#mark_visited!" do
    it "updates the viewer's scene_participant last_visited_at when present" do
      sp = double("scene_participant")
      find_by_rel = double("find_by rel")
      allow(scene).to receive(:scene_participants).and_return(find_by_rel)
      allow(find_by_rel).to receive(:find_by).with(user: current_user).and_return(sp)
      expect(sp).to receive(:update).with(last_visited_at: kind_of(ActiveSupport::TimeWithZone))

      presenter.mark_visited!
    end

    it "does nothing when the viewer has no scene_participant" do
      find_by_rel = double("find_by rel")
      allow(scene).to receive(:scene_participants).and_return(find_by_rel)
      allow(find_by_rel).to receive(:find_by).with(user: current_user).and_return(nil)

      expect { presenter.mark_visited! }.not_to raise_error
    end
  end
end
