require "rails_helper"

RSpec.describe CharacterImagePolicy do
  let(:owner) { build_stubbed(:user) }
  let(:other) { build_stubbed(:user) }
  let(:character) { build_stubbed(:character, user: owner) }
  let(:image) { build_stubbed(:character_image, character: character) }

  describe "#manage?" do
    it "is true for the player who owns the character" do
      expect(described_class.new(owner, image).manage?).to be(true)
    end

    it "is false for anyone else (including the GM)" do
      expect(described_class.new(other, image).manage?).to be(false)
    end
  end

  describe "CRUD predicates delegate to #manage?" do
    # Both states per predicate, so the delegation is pinned against a `super`
    # (false) mutant and a hard-coded-true mutant alike.
    %i[create? update? destroy?].each do |predicate|
      it "#{predicate} is true for the owning player" do
        expect(described_class.new(owner, image).public_send(predicate)).to be(true)
      end

      it "#{predicate} is false for a non-owner" do
        expect(described_class.new(other, image).public_send(predicate)).to be(false)
      end
    end
  end
end
