require "rails_helper"

RSpec.describe NotebookEntryVersionPolicy do
  let(:user) { build_stubbed(:user) }
  let(:game) { instance_double(Game) }
  let(:entry) { instance_double(NotebookEntry) }
  let(:version) { build_stubbed(:notebook_entry_version) }

  subject(:policy) { described_class.new(user, version) }

  before do
    allow(version).to receive(:notebook_entry).and_return(entry)
    allow(entry).to receive(:game).and_return(game)
    allow(game).to receive(:game_master?).with(user).and_return(gm)
    allow(game).to receive(:active_member?).with(user).and_return(active)
  end

  describe "#show?" do
    context "an active game master" do
      let(:gm) { true }
      let(:active) { true }

      it "may read note history" do
        expect(policy.show?).to be(true)
      end
    end

    context "a banned (or removed) game master" do
      let(:gm) { true }
      let(:active) { false }

      it "may not read note history — a banned GM keeps no notebook access" do
        expect(policy.show?).to be(false)
      end
    end

    context "an active non-GM member" do
      let(:gm) { false }
      let(:active) { true }

      it "may not read note history — the notebook is GM-only" do
        expect(policy.show?).to be(false)
      end
    end

    context "a non-member" do
      let(:gm) { false }
      let(:active) { false }

      it "may not read note history" do
        expect(policy.show?).to be(false)
      end
    end
  end
end
