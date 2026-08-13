require "rails_helper"

RSpec.describe NotebookEntryPolicy do
  let(:user) { build_stubbed(:user) }
  let(:game) { instance_double(Game) }
  let(:entry) { build_stubbed(:notebook_entry) }

  subject(:policy) { described_class.new(user, entry) }

  before do
    allow(entry).to receive(:game).and_return(game)
  end

  describe "#index? / #show? / #create? / #update? / #destroy? / #manage? (GM only)" do
    it "are true for the GM" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      expect(policy.index?).to be(true)
      expect(policy.show?).to be(true)
      expect(policy.create?).to be(true)
      expect(policy.update?).to be(true)
      expect(policy.destroy?).to be(true)
      expect(policy.manage?).to be(true)
    end

    it "are false for a non-GM" do
      allow(game).to receive(:game_master?).with(user).and_return(false)
      expect(policy.index?).to be(false)
      expect(policy.show?).to be(false)
      expect(policy.create?).to be(false)
      expect(policy.update?).to be(false)
      expect(policy.destroy?).to be(false)
      expect(policy.manage?).to be(false)
    end
  end

  describe "new?/edit? aliases" do
    it "new? mirrors create?" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      expect(policy.new?).to eq(policy.create?)
    end

    it "edit? mirrors update?" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      expect(policy.edit?).to eq(policy.update?)
    end
  end
end
