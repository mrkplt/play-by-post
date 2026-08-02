require "rails_helper"

RSpec.describe ScenePolicy do
  let(:user) { build_stubbed(:user) }
  let(:game) { instance_double(Game) }
  let(:scene) { build_stubbed(:scene) }

  subject(:policy) { described_class.new(user, scene) }

  before do
    allow(scene).to receive(:game).and_return(game)
  end

  def stub_game(gm: false, viewable: false)
    allow(game).to receive(:game_master?).with(user).and_return(gm)
    allow(game).to receive(:viewable_by?).with(user).and_return(viewable)
  end

  def stub_membership(gm: false, active: false, present: true)
    membership = present ? instance_double(GameMember, game_master?: gm, active?: active) : nil
    allow(game).to receive(:member_for).with(user).and_return(membership)
  end

  def stub_private(value)
    allow(scene).to receive(:private?).and_return(value)
  end

  def stub_participant(value)
    allow(scene).to receive(:participant?).with(user).and_return(value)
  end

  describe "#visible? (private-scene gate)" do
    it "is true for the GM even for a private scene they have not joined" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      stub_private(true)
      stub_participant(false)
      expect(policy.visible?).to be(true)
    end

    it "is true for a public scene" do
      allow(game).to receive(:game_master?).with(user).and_return(false)
      stub_private(false)
      expect(policy.visible?).to be(true)
    end

    it "is true for a private scene the user participates in" do
      allow(game).to receive(:game_master?).with(user).and_return(false)
      stub_private(true)
      stub_participant(true)
      expect(policy.visible?).to be(true)
    end

    it "is false for a private scene the user neither runs nor joined" do
      allow(game).to receive(:game_master?).with(user).and_return(false)
      stub_private(true)
      stub_participant(false)
      expect(policy.visible?).to be(false)
    end
  end

  describe "#show?" do
    it "is false when the game is not viewable, even if the scene is visible" do
      stub_game(viewable: false, gm: true)
      expect(policy.show?).to be(false)
    end

    it "is false when viewable but the private scene is not visible to the user" do
      stub_game(viewable: true, gm: false)
      stub_private(true)
      stub_participant(false)
      expect(policy.show?).to be(false)
    end

    it "is true when viewable and the scene is visible" do
      stub_game(viewable: true, gm: false)
      stub_private(false)
      expect(policy.show?).to be(true)
    end
  end

  describe "#create? / #new? / #resolve? / #manage_participants? (GM only)" do
    it "are true for the GM" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      expect(policy.create?).to be(true)
      expect(policy.new?).to be(true)
      expect(policy.resolve?).to be(true)
      expect(policy.manage_participants?).to be(true)
    end

    it "are false for a non-GM" do
      allow(game).to receive(:game_master?).with(user).and_return(false)
      expect(policy.create?).to be(false)
      expect(policy.new?).to be(false)
      expect(policy.resolve?).to be(false)
      expect(policy.manage_participants?).to be(false)
    end
  end

  describe "#join? (write member)" do
    it "is true for the GM" do
      stub_membership(gm: true)
      expect(policy.join?).to be(true)
    end

    it "is true for an active member" do
      stub_membership(active: true)
      expect(policy.join?).to be(true)
    end

    it "is false for a non-active member (e.g. removed)" do
      stub_membership(gm: false, active: false)
      expect(policy.join?).to be(false)
    end

    it "is false for a non-member" do
      stub_membership(present: false)
      expect(policy.join?).to be(false)
    end
  end

  describe "#reply_by_email? (participant only)" do
    it "is true for a participant" do
      stub_participant(true)
      expect(policy.reply_by_email?).to be(true)
    end

    it "is false for a non-participant" do
      stub_participant(false)
      expect(policy.reply_by_email?).to be(false)
    end
  end

  describe "#permitted_attributes" do
    it "permits title, private, and parent_scene_id" do
      expect(policy.permitted_attributes).to eq(%i[title private parent_scene_id])
    end
  end

  describe ScenePolicy::Scope do
    let(:visible_relation) { double("visible scenes") }
    let(:scenes_relation) { double("scenes", visible_to: visible_relation) }

    subject(:scope) { described_class.new(user, game) }

    it "resolves to the game's scenes visible to the user" do
      allow(game).to receive(:scenes).and_return(scenes_relation)
      expect(scope.resolve).to eq(visible_relation)
      expect(scenes_relation).to have_received(:visible_to).with(user, game)
    end
  end
end
