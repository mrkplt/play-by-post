require "rails_helper"

RSpec.describe GamePolicy do
  let(:user) { build_stubbed(:user) }
  let(:game) { build_stubbed(:game) }

  subject(:policy) { described_class.new(user, game) }

  def stub_game(gm: false, viewable: false)
    allow(game).to receive(:game_master?).with(user).and_return(gm)
    allow(game).to receive(:viewable_by?).with(user).and_return(viewable)
  end

  describe "#show? / #view? / #manage_players? / #export? (any viewer)" do
    it "are true when the game is viewable" do
      stub_game(viewable: true)
      expect(policy.show?).to be(true)
      expect(policy.view?).to be(true)
      expect(policy.manage_players?).to be(true)
      expect(policy.export?).to be(true)
    end

    it "are false when the game is not viewable" do
      stub_game(viewable: false)
      expect(policy.show?).to be(false)
      expect(policy.view?).to be(false)
      expect(policy.manage_players?).to be(false)
      expect(policy.export?).to be(false)
    end
  end

  describe "#create? / #new? (any authenticated user)" do
    it "is always true" do
      expect(policy.create?).to be(true)
      expect(policy.new?).to be(true)
    end
  end

  describe "#update? / #edit? / #manage? (GM only)" do
    it "is true for the GM" do
      stub_game(gm: true)
      expect(policy.update?).to be(true)
      expect(policy.edit?).to be(true)
      expect(policy.manage?).to be(true)
    end

    it "is false for a non-GM" do
      stub_game(gm: false)
      expect(policy.update?).to be(false)
      expect(policy.edit?).to be(false)
      expect(policy.manage?).to be(false)
    end
  end

  describe "#destroy? (GM only)" do
    it "is true for the GM" do
      stub_game(gm: true)
      expect(policy.destroy?).to be(true)
    end

    it "is false for a non-GM" do
      stub_game(gm: false)
      expect(policy.destroy?).to be(false)
    end
  end

  describe "#contribute? (GM, or an active player when contributions are on)" do
    before do
      allow(game).to receive(:game_master?).with(user).and_return(false)
      allow(game).to receive(:active_member?).with(user).and_return(false)
      allow(game).to receive(:player_contributions_enabled?).and_return(false)
    end

    it "is true for the GM regardless of the setting" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      expect(policy.contribute?).to be(true)
    end

    it "is true for an active member when contributions are enabled" do
      allow(game).to receive(:active_member?).with(user).and_return(true)
      allow(game).to receive(:player_contributions_enabled?).and_return(true)
      expect(policy.contribute?).to be(true)
    end

    it "is false for an active member when contributions are disabled" do
      allow(game).to receive(:active_member?).with(user).and_return(true)
      expect(policy.contribute?).to be(false)
    end

    it "is false for a non-member even when contributions are enabled" do
      allow(game).to receive(:player_contributions_enabled?).and_return(true)
      expect(policy.contribute?).to be(false)
    end
  end

  describe "#write_access? (active member)" do
    it "is true for an active member (a GM is an active member)" do
      allow(game).to receive(:active_member?).with(user).and_return(true)
      expect(policy.write_access?).to be(true)
    end

    it "is false for a non-active member (removed/banned, even if GM role)" do
      allow(game).to receive(:active_member?).with(user).and_return(false)
      expect(policy.write_access?).to be(false)
    end
  end

  describe "#export_scene_selection" do
    def stub_membership(gm: false, removed: false)
      allow(game).to receive(:member_for).with(user)
        .and_return(instance_double(GameMember, game_master?: gm, removed?: removed))
    end

    it "gives the GM every scene" do
      stub_membership(gm: true)
      expect(policy.export_scene_selection).to eq(:all)
    end

    it "limits a removed member to scenes they participated in" do
      stub_membership(gm: false, removed: true)
      expect(policy.export_scene_selection).to eq(:participating)
    end

    it "gives everyone else the normally-visible set" do
      stub_membership(gm: false, removed: false)
      expect(policy.export_scene_selection).to eq(:visible)
    end

    it "defaults to the visible set when there is no membership" do
      allow(game).to receive(:member_for).with(user).and_return(nil)
      expect(policy.export_scene_selection).to eq(:visible)
    end
  end
end
