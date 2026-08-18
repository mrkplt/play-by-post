require "rails_helper"

RSpec.describe UserImagePolicy do
  let(:user) { build_stubbed(:user) }
  let(:other_user) { build_stubbed(:user) }

  describe "#manage?" do
    it "is true when the image belongs to the user" do
      image = build_stubbed(:user_image, user: user)
      expect(described_class.new(user, image).manage?).to be(true)
    end

    it "is false when the image belongs to someone else" do
      image = build_stubbed(:user_image, user: other_user)
      expect(described_class.new(user, image).manage?).to be(false)
    end
  end

  describe "CRUD predicates delegate to #manage?" do
    let(:own_image) { build_stubbed(:user_image, user: user) }
    let(:their_image) { build_stubbed(:user_image, user: other_user) }

    # Each predicate is asserted in BOTH states so the delegation to manage? is
    # pinned (a mutant swapping the body for `super`/false is killed by the
    # true case, and one hard-coding true is killed by the false case).
    %i[create? update? destroy?].each do |predicate|
      it "#{predicate} is true for the owner" do
        expect(described_class.new(user, own_image).public_send(predicate)).to be(true)
      end

      it "#{predicate} is false for a non-owner" do
        expect(described_class.new(user, their_image).public_send(predicate)).to be(false)
      end
    end
  end
end
