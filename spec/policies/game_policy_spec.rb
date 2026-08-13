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

  describe "#write_access? (GM or active member)" do
    def stub_membership(gm: false, active: false, present: true)
      membership = present ? instance_double(GameMember, game_master?: gm, active?: active) : nil
      allow(game).to receive(:member_for).with(user).and_return(membership)
    end

    it "is true for the GM" do
      stub_membership(gm: true)
      expect(policy.write_access?).to be(true)
    end

    it "is true for an active member" do
      stub_membership(active: true)
      expect(policy.write_access?).to be(true)
    end

    it "is false for a member who is neither GM nor active (e.g. removed)" do
      stub_membership(gm: false, active: false)
      expect(policy.write_access?).to be(false)
    end

    it "is false for a non-member" do
      stub_membership(present: false)
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
