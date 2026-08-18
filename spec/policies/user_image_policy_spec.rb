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

    it "create? follows manage?" do
      expect(described_class.new(user, own_image).create?).to be(true)
    end

    it "update? follows manage?" do
      expect(described_class.new(user, their_image).update?).to be(false)
    end

    it "destroy? follows manage?" do
      expect(described_class.new(user, own_image).destroy?).to be(true)
    end
  end
end
