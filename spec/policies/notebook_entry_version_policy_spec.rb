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
  end

  describe "#show?" do
    it "is true for the GM" do
      allow(game).to receive(:game_master?).with(user).and_return(true)
      expect(policy.show?).to be(true)
    end

    it "is false for a non-GM" do
      allow(game).to receive(:game_master?).with(user).and_return(false)
      expect(policy.show?).to be(false)
    end
  end
end
