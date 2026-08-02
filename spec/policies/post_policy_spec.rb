require "rails_helper"

RSpec.describe PostPolicy do
  let(:user) { build_stubbed(:user) }
  # scene/game are build_stubbed rather than instance_double: PostPolicy's typed
  # #scene/#game helpers reject RSpec doubles at the sorbet-runtime boundary.
  let(:game) { build_stubbed(:game) }
  let(:scene) { build_stubbed(:scene, game: game) }
  let(:post) { build_stubbed(:post) }

  subject(:policy) { described_class.new(user, post) }

  before do
    allow(post).to receive(:scene).and_return(scene)
  end

  def stub_participant(value)
    allow(scene).to receive(:participant?).with(user).and_return(value)
  end

  def stub_gm(value)
    allow(game).to receive(:game_master?).with(user).and_return(value)
  end

  def stub_membership(gm: false, active: false, present: true)
    membership = present ? instance_double(GameMember, game_master?: gm, active?: active) : nil
    allow(game).to receive(:member_for).with(user).and_return(membership)
  end

  describe "#update? / #edit? (Post#editable_by?)" do
    it "is true when the post is editable by the user" do
      allow(post).to receive(:editable_by?).with(user).and_return(true)
      expect(policy.update?).to be(true)
      expect(policy.edit?).to be(true)
    end

    it "is false when the post is not editable by the user" do
      allow(post).to receive(:editable_by?).with(user).and_return(false)
      expect(policy.update?).to be(false)
      expect(policy.edit?).to be(false)
    end
  end

  describe "#participate? / #mark_read? (participant or GM)" do
    it "is true for a scene participant" do
      stub_participant(true)
      expect(policy.participate?).to be(true)
      expect(policy.mark_read?).to be(true)
    end

    it "is true for the GM even if not a participant" do
      stub_participant(false)
      stub_gm(true)
      expect(policy.participate?).to be(true)
    end

    it "is false for a non-participant non-GM" do
      stub_participant(false)
      stub_gm(false)
      expect(policy.participate?).to be(false)
      expect(policy.mark_read?).to be(false)
    end
  end

  describe "#create? (participant/GM AND active member)" do
    it "is true for a participant who is an active member" do
      stub_participant(true)
      stub_membership(active: true)
      expect(policy.create?).to be(true)
    end

    it "is true for a participant whose membership is the GM role" do
      stub_participant(true)
      stub_membership(gm: true, active: false)
      expect(policy.create?).to be(true)
    end

    it "is false for a participant who is not a writer (e.g. removed)" do
      stub_participant(true)
      stub_membership(gm: false, active: false)
      expect(policy.create?).to be(false)
    end

    it "is false for a participant who is not a member at all" do
      stub_participant(true)
      stub_membership(present: false)
      expect(policy.create?).to be(false)
    end

    it "is false for an active member who cannot take part in the scene" do
      stub_participant(false)
      stub_gm(false)
      stub_membership(active: true)
      expect(policy.create?).to be(false)
    end
  end
end
