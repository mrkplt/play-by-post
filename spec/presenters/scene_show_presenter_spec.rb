require "rails_helper"

RSpec.describe SceneShowPresenter do
  let(:scene) { build(:scene, created_at: Time.zone.parse("2024-03-10 09:00:00")) }
  let(:scene_presenter) { ScenePresenter.new(scene) }
  let(:current_user) { build_stubbed(:user) }
  let(:game) { build_stubbed(:game) }
  let(:urls) { double(join_game_scene_participants_path: "/games/1/scenes/2/participants/join") }

  subject(:presenter) { described_class.new(scene_presenter, game: game, urls: urls, current_user: current_user) }

  describe "#mute_toggle_label" do
    it "returns Unmute notifications when muted" do
      expect(presenter.mute_toggle_label(true)).to eq("Unmute notifications")
    end

    it "returns Mute notifications when not muted" do
      expect(presenter.mute_toggle_label(false)).to eq("Mute notifications")
    end
  end

  describe "#muted?" do
    it "asks NotificationPreference whether the viewer has muted this scene" do
      allow(NotificationPreference).to receive(:muted?).with(scene, current_user).and_return(true)
      expect(presenter.muted?).to be(true)
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
    it "returns child scenes visible to the viewer, ordered by creation, wrapped as presenters" do
      child = build_stubbed(:scene)
      visible_rel = double("visible rel")
      ordered_rel = double("ordered rel")
      allow(scene).to receive(:child_scenes).and_return(double(visible_to: visible_rel))
      allow(visible_rel).to receive(:order).with(:created_at).and_return(ordered_rel)
      allow(ordered_rel).to receive(:to_a).and_return([ child ])

      result = presenter.visible_child_scenes
      expect(result.length).to eq(1)
      expect(result.first).to be_a(ScenePresenter)
    end
  end
end
