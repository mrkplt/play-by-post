require "rails_helper"

RSpec.describe CharacterPolicy do
  let(:user) { build_stubbed(:user) }
  let(:owner) { build_stubbed(:user) }
  let(:game) { instance_double(Game) }
  let(:character) { build_stubbed(:character, user: owner) }

  subject(:policy) { described_class.new(user, character) }

  before do
    allow(character).to receive(:game).and_return(game)
  end

  def stub_game(gm: false, viewable: false)
    allow(game).to receive(:game_master?).with(user).and_return(gm)
    allow(game).to receive(:viewable_by?).with(user).and_return(viewable)
  end

  def stub_membership(gm: false, active: false, present: true)
    membership = present ? instance_double(GameMember, game_master?: gm, active?: active) : nil
    allow(game).to receive(:member_for).with(user).and_return(membership)
  end

  def stub_editable(value)
    allow(character).to receive(:editable_by?).with(user, game).and_return(value)
  end

  def stub_hidden(value)
    allow(character).to receive(:hidden?).and_return(value)
  end

  describe "#show?" do
    it "is false when the game is not viewable, even if the sheet is visible" do
      stub_game(viewable: false)
      stub_hidden(false)
      stub_editable(true)
      expect(policy.show?).to be(false)
    end

    it "is false when viewable but the sheet is hidden from this user" do
      stub_game(viewable: true)
      stub_hidden(true)
      stub_editable(false)
      expect(policy.show?).to be(false)
    end

    it "is true when viewable and the sheet is visible" do
      stub_game(viewable: true)
      stub_hidden(false)
      stub_editable(false)
      expect(policy.show?).to be(true)
    end
  end

  describe "#visible? (hidden-sheet gate)" do
    it "is true for an unhidden sheet regardless of editability" do
      stub_hidden(false)
      stub_editable(false)
      expect(policy.visible?).to be(true)
    end

    it "is true for a hidden sheet the user may edit (owner or GM)" do
      stub_hidden(true)
      stub_editable(true)
      expect(policy.visible?).to be(true)
    end

    it "is false for a hidden sheet the user may not edit" do
      stub_hidden(true)
      stub_editable(false)
      expect(policy.visible?).to be(false)
    end
  end

  describe "#create? / #new? (write member)" do
    it "is true for the GM" do
      stub_membership(gm: true)
      expect(policy.create?).to be(true)
    end

    it "is true for an active member" do
      stub_membership(active: true)
      expect(policy.create?).to be(true)
    end

    it "is false for a member who is neither GM nor active (e.g. removed)" do
      stub_membership(gm: false, active: false)
      expect(policy.create?).to be(false)
    end

    it "is false for a non-member" do
      stub_membership(present: false)
      expect(policy.create?).to be(false)
    end

    it "new? mirrors create?" do
      stub_membership(active: true)
      expect(policy.new?).to be(true)
    end
  end

  describe "#update? / #edit? (write member AND editable)" do
    it "is true for an active member who may edit the sheet" do
      stub_membership(active: true)
      stub_editable(true)
      expect(policy.update?).to be(true)
    end

    it "is false for an active member who may not edit the sheet" do
      stub_membership(active: true)
      stub_editable(false)
      expect(policy.update?).to be(false)
    end

    it "is false for a non-writer even if they own the sheet (e.g. removed owner)" do
      stub_membership(gm: false, active: false)
      stub_editable(true)
      expect(policy.update?).to be(false)
    end

    it "edit? mirrors update?" do
      stub_membership(active: true)
      stub_editable(true)
      expect(policy.edit?).to be(true)
    end
  end

  describe "#manage_roster? (GM only)" do
    it "is true for the GM" do
      stub_game(gm: true)
      expect(policy.manage_roster?).to be(true)
    end

    it "is false for a non-GM" do
      stub_game(gm: false)
      expect(policy.manage_roster?).to be(false)
    end
  end

  describe "#archive? / #restore? / #assign_owner? (GM only)" do
    it "is true for the GM" do
      stub_game(gm: true)
      expect(policy.archive?).to be(true)
      expect(policy.restore?).to be(true)
      expect(policy.assign_owner?).to be(true)
    end

    it "is false for a non-GM" do
      stub_game(gm: false)
      expect(policy.archive?).to be(false)
      expect(policy.restore?).to be(false)
      expect(policy.assign_owner?).to be(false)
    end

    it "archive? and restore? delegate to manage_roster?" do
      allow(policy).to receive(:manage_roster?).and_return(true)
      expect(policy.archive?).to be(true)
      expect(policy.restore?).to be(true)

      allow(policy).to receive(:manage_roster?).and_return(false)
      expect(policy.archive?).to be(false)
      expect(policy.restore?).to be(false)
    end
  end

  describe "#permitted_attributes" do
    it "permits name, content, and hidden (never user_id — owner is set by the controller)" do
      expect(policy.permitted_attributes).to eq(%i[name content hidden])
    end
  end

  describe CharacterPolicy::Scope do
    let(:game) { instance_double(Game) }
    let(:visible_relation) { double("visible characters") }
    let(:characters_relation) { double("characters", visible_to: visible_relation) }

    subject(:scope) { described_class.new(user, game) }

    it "resolves to the game's characters visible to the user" do
      allow(game).to receive(:characters).and_return(characters_relation)
      expect(scope.resolve).to eq(visible_relation)
      expect(characters_relation).to have_received(:visible_to).with(user, game)
    end
  end
end
