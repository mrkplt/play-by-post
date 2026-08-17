require "rails_helper"

RSpec.describe NotebookEntryPolicy do
  let(:user) { build_stubbed(:user) }
  let(:game) { instance_double(Game) }
  let(:entry) { build_stubbed(:notebook_entry) }

  subject(:policy) { described_class.new(user, entry) }

  before do
    allow(entry).to receive(:game).and_return(game)
    allow(game).to receive(:game_master?).with(user).and_return(gm)
    allow(game).to receive(:active_member?).with(user).and_return(active)
  end

  describe "#index? / #show? / #create? / #update? / #destroy? / #manage? (active GM only)" do
    context "an active game master" do
      let(:gm) { true }
      let(:active) { true }

      it "may work the notebook in every direction" do
        expect(policy.index?).to be(true)
        expect(policy.show?).to be(true)
        expect(policy.create?).to be(true)
        expect(policy.update?).to be(true)
        expect(policy.destroy?).to be(true)
        expect(policy.manage?).to be(true)
      end
    end

    context "a banned (or removed) game master" do
      let(:gm) { true }
      let(:active) { false }

      it "may neither read nor write notes — a banned GM keeps no notebook access" do
        expect(policy.index?).to be(false)
        expect(policy.show?).to be(false)
        expect(policy.create?).to be(false)
        expect(policy.update?).to be(false)
        expect(policy.destroy?).to be(false)
        expect(policy.manage?).to be(false)
      end
    end

    context "an active non-GM member" do
      let(:gm) { false }
      let(:active) { true }

      it "may not touch the notebook — it is GM-only" do
        expect(policy.index?).to be(false)
        expect(policy.manage?).to be(false)
      end
    end

    context "a non-member" do
      let(:gm) { false }
      let(:active) { false }

      it "may not touch the notebook" do
        expect(policy.manage?).to be(false)
      end
    end
  end

  describe "new?/edit? aliases" do
    let(:gm) { true }
    let(:active) { true }

    it "new? mirrors create?" do
      expect(policy.new?).to eq(policy.create?)
    end

    it "edit? mirrors update?" do
      expect(policy.edit?).to eq(policy.update?)
    end
  end
end
