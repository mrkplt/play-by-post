require "rails_helper"

RSpec.describe ScenePageAction do
  let(:scene) { build(:scene) }
  let(:active_membership) { build_stubbed(:game_member) }
  let(:removed_membership) { build_stubbed(:game_member, :removed) }

  describe ScenePageAction::Viewer do
    def viewer_for(membership)
      described_class.new(can_manage: false, is_participant: false, membership: membership)
    end

    describe "#active_member?" do
      it "is true for an active membership" do
        expect(viewer_for(active_membership).active_member?).to be(true)
      end

      it "is false for a membership that is not active" do
        expect(viewer_for(removed_membership).active_member?).to be(false)
      end

      # Explicitly `false`, not nil: the method is typed T::Boolean, so the
      # absent-membership case must return an actual boolean rather than the
      # nil that safe navigation alone would yield.
      it "is false, not nil, when there is no membership" do
        expect(viewer_for(nil).active_member?).to be(false)
      end
    end
  end

  describe ".resolved_for" do
    let(:game) { build_stubbed(:game) }
    let(:urls) { double(join_game_scene_participants_path: "/join-here") }

    def resolved_for(scene, **overrides)
      viewer = described_class::Viewer.new(
        **{ can_manage: false, is_participant: false, membership: active_membership }.merge(overrides)
      )
      described_class.resolved_for(
        scene: scene, viewer: viewer,
        route_args: described_class::RouteArgs.new(urls: urls, game: game)
      )
    end

    it "resolves the action's route against the supplied url helpers" do
      expect(resolved_for(scene)).to have_attributes(
        label: "Join Scene",
        href: "/join-here",
        http_method: :post
      )
      expect(urls).to have_received(:join_game_scene_participants_path).with(game, scene)
    end

    it "is nil when there is no action, without touching the url helpers" do
      expect(resolved_for(scene, is_participant: true)).to be_nil
      expect(urls).not_to have_received(:join_game_scene_participants_path)
    end
  end

  describe ".for" do
    def action_for(scene, membership:, **overrides)
      viewer = described_class::Viewer.new(
        **{ can_manage: false, is_participant: false, membership: membership }.merge(overrides)
      )
      described_class.for(scene: scene, viewer: viewer)
    end

    it "is a Join Scene POST action for an eligible non-participant, non-GM, active member on an open public scene" do
      expect(action_for(scene, membership: active_membership)).to have_attributes(
        label: "Join Scene",
        route: :join_game_scene_participants_path,
        http_method: :post
      )
    end

    it "is nil when already a participant" do
      expect(action_for(scene, membership: active_membership, is_participant: true)).to be_nil
    end

    it "is nil for the GM" do
      expect(action_for(scene, membership: active_membership, can_manage: true)).to be_nil
    end

    it "is nil for a private scene" do
      expect(action_for(build(:scene, :private), membership: active_membership)).to be_nil
    end

    it "is nil when membership is not active" do
      expect(action_for(scene, membership: removed_membership)).to be_nil
    end

    it "is nil when there is no membership at all" do
      expect(action_for(scene, membership: nil)).to be_nil
    end

    it "is nil for a resolved scene (not Join — resolved scenes fall through to the summary branch)" do
      expect(action_for(build(:scene, :resolved), membership: active_membership)).to be_nil
    end

    it "is a Write Summary GET action for the GM on a resolved scene with no summary yet" do
      expect(action_for(build(:scene, :resolved), membership: active_membership, can_manage: true))
        .to have_attributes(
          label: "Write Summary",
          route: :new_game_scene_scene_summary_path,
          http_method: nil
        )
    end

    it "is nil for a resolved scene that already has a summary" do
      resolved_scene = build(:scene, :resolved)
      create(:scene_summary, scene: resolved_scene)
      expect(action_for(resolved_scene, membership: active_membership, can_manage: true)).to be_nil
    end

    it "is nil for a non-GM on a resolved scene" do
      expect(action_for(build(:scene, :resolved), membership: active_membership, can_manage: false, is_participant: true))
        .to be_nil
    end
  end
end
