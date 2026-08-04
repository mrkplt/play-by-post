require "rails_helper"

RSpec.describe FeedbackPolicy do
  let(:feedback) { build_stubbed(:feedback) }

  describe "#create?" do
    it "permits a signed-in user" do
      policy = described_class.new(build_stubbed(:user), feedback)
      expect(policy.create?).to be(true)
    end

    it "denies an unauthenticated (nil) user" do
      policy = described_class.new(nil, feedback)
      expect(policy.create?).to be(false)
    end
  end
end
