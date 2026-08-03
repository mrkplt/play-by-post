require "rails_helper"

RSpec.describe UserProfilePolicy do
  let(:owner) { build_stubbed(:user) }
  let(:profile) { build_stubbed(:user_profile, user: owner) }

  describe "owner rule" do
    context "when the user owns the profile" do
      subject(:policy) { described_class.new(owner, profile) }

      it "permits show?, update?/edit?, and manage?" do
        expect(policy.show?).to be(true)
        expect(policy.update?).to be(true)
        expect(policy.edit?).to be(true)
        expect(policy.manage?).to be(true)
      end
    end

    context "when the user does not own the profile" do
      subject(:policy) { described_class.new(build_stubbed(:user), profile) }

      it "denies show?, update?/edit?, and manage?" do
        expect(policy.show?).to be(false)
        expect(policy.update?).to be(false)
        expect(policy.edit?).to be(false)
        expect(policy.manage?).to be(false)
      end
    end
  end
end
