require "rails_helper"

RSpec.describe SceneShowPresenter do
  let(:scene) { build(:scene, created_at: Time.zone.parse("2024-03-10 09:00:00")) }
  let(:scene_presenter) { ScenePresenter.new(scene) }
  let(:current_user) { build_stubbed(:user) }
  let(:game) { build_stubbed(:game) }
  let(:urls) { double(join_game_scene_participants_path: "/games/1/scenes/2/participants/join") }

  subject(:presenter) do
    described_class.new(scene_presenter, game: game, urls: urls, current_user: current_user)
  end

  describe "#scene_presenter" do
    it "returns the wrapped ScenePresenter" do
      expect(presenter.scene_presenter).to eq(scene_presenter)
    end
  end

  describe "#page_action" do
    let(:membership) { build_stubbed(:game_member) }

    before do
      allow(scene).to receive(:participant?).with(current_user).and_return(false)
      allow(game).to receive(:member_for).with(current_user).and_return(membership)
    end

    def page_action(**overrides)
      presenter.page_action(**{ can_manage: false }.merge(overrides))
    end

    it "wraps the viewer facts and its own scene when asking for the action" do
      allow(ScenePageAction).to receive(:for).and_return(ScenePageAction::JOIN)

      page_action

      expect(ScenePageAction).to have_received(:for) do |scene:, viewer:|
        expect(scene).to eq(self.scene)
        expect(viewer).to have_attributes(
          can_manage: false, is_participant: false, membership: membership
        )
      end
    end

    it "resolves the action's route against the caller's url helpers" do
      allow(ScenePageAction).to receive(:for).and_return(ScenePageAction::JOIN)

      expect(page_action).to have_attributes(
        label: "Join Scene",
        href: "/games/1/scenes/2/participants/join",
        http_method: :post
      )
      expect(urls).to have_received(:join_game_scene_participants_path).with(game, scene)
    end

    it "is nil when there is no action, without touching the url helpers" do
      allow(ScenePageAction).to receive(:for).and_return(nil)

      expect(page_action).to be_nil
      expect(urls).not_to have_received(:join_game_scene_participants_path)
    end
  end

  describe "#participant?" do
    it "asks the model whether the viewer participates" do
      allow(scene).to receive(:participant?).with(current_user).and_return(true)
      expect(presenter.participant?).to be(true)
    end
  end

  describe "#viewer_membership" do
    it "asks the game for the viewer's membership" do
      membership = build_stubbed(:game_member)
      allow(game).to receive(:member_for).with(current_user).and_return(membership)
      expect(presenter.viewer_membership).to eq(membership)
    end
  end

  describe "#muted?" do
    it "asks NotificationPreference whether the viewer has muted this scene" do
      allow(NotificationPreference).to receive(:muted?).with(scene, current_user).and_return(true)
      expect(presenter.muted?).to be(true)
    end
  end

  describe "#hide_ooc?" do
    it "is true when the viewer's profile has hide_ooc set" do
      profile = double("profile", hide_ooc?: true)
      allow(current_user).to receive(:user_profile).and_return(profile)
      expect(presenter.hide_ooc?).to be(true)
    end

    it "is false when the viewer has no profile" do
      allow(current_user).to receive(:user_profile).and_return(nil)
      expect(presenter.hide_ooc?).to be(false)
    end
  end

  describe "#visible_child_scenes" do
    it "returns child scenes visible to the viewer, ordered by creation" do
      children = [ build_stubbed(:scene) ]
      visible_rel = double("visible rel")
      ordered_rel = double("ordered rel")
      allow(scene).to receive(:child_scenes).and_return(double(visible_to: visible_rel))
      allow(visible_rel).to receive(:order).with(:created_at).and_return(ordered_rel)
      allow(ordered_rel).to receive(:to_a).and_return(children)

      expect(presenter.visible_child_scenes).to eq(children)
    end
  end

  describe "#draft" do
    it "returns the viewer's draft post in this scene, if any" do
      draft = build_stubbed(:post, :draft)
      drafts_rel = double("drafts rel")
      allow(scene).to receive(:posts).and_return(double(drafts: drafts_rel))
      allow(drafts_rel).to receive(:find_by).with(user: current_user).and_return(draft)

      expect(presenter.draft).to eq(draft)
    end
  end

  describe "#new_post" do
    it "returns a blank post for the composer" do
      expect(presenter.new_post).to be_a(Post).and be_new_record
    end
  end

  describe "#posts_empty? and #post_presenters" do
    it "reports empty when the scene has no published posts" do
      allow(scene).to receive_message_chain(:posts, :published, :includes, :order, :to_a).and_return([])
      expect(presenter.posts_empty?).to be(true)
      expect(presenter.post_presenters).to eq([])
    end

    it "wraps published posts for display" do
      post = build_stubbed(:post)
      allow(scene).to receive_message_chain(:posts, :published, :includes, :order, :to_a).and_return([ post ])
      allow(scene).to receive_message_chain(:scene_participants, :includes, :to_a).and_return([])

      expect(presenter.posts_empty?).to be(false)
      expect(presenter.post_presenters.length).to eq(1)
      expect(presenter.post_presenters.first).to be_a(PostPresenter)
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
