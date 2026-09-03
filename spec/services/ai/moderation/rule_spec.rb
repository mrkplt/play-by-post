require "rails_helper"

# Rule is the shared surface for moderation rules (modules under Rules): the
# block/allow Outcome builders and the Outcome value object.
RSpec.describe Ai::Moderation::Rule do
  describe ".block" do
    it "builds a moderated Outcome carrying the reason" do
      outcome = described_class.block("nope")
      expect(outcome.moderated?).to be(true)
      expect(outcome.reason).to eq("nope")
    end
  end

  describe ".allow" do
    it "builds a non-moderated Outcome with an empty reason" do
      outcome = described_class.allow
      expect(outcome.moderated?).to be(false)
      expect(outcome.reason).to eq("")
    end
  end
end
