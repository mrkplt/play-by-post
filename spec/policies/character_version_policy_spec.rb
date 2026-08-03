require "rails_helper"

RSpec.describe CharacterVersionPolicy do
  let(:user) { build_stubbed(:user) }
  let(:game) { instance_double(Game) }
  let(:character) { instance_double(Character) }
  let(:version) { build_stubbed(:character_version) }

  subject(:policy) { described_class.new(user, version) }

  before do
    allow(version).to receive(:character).and_return(character)
    allow(character).to receive(:game).and_return(game)
  end

  describe "#show? (game access)" do
    it "is true when the game is viewable by the user" do
      allow(game).to receive(:viewable_by?).with(user).and_return(true)
      expect(policy.show?).to be(true)
    end

    it "is false when the game is not viewable by the user" do
      allow(game).to receive(:viewable_by?).with(user).and_return(false)
      expect(policy.show?).to be(false)
    end
  end
end
