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
    it "create? follows manage? for the owner" do
      expect(described_class.new(owner, image).create?).to be(true)
    end

    it "update? follows manage? for a non-owner" do
      expect(described_class.new(other, image).update?).to be(false)
    end

    it "destroy? follows manage? for the owner" do
      expect(described_class.new(owner, image).destroy?).to be(true)
    end
  end
end
