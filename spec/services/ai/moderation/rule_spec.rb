require "rails_helper"

# The Rule base: an abstract #moderate (raises if a subclass forgets it) and the
# block/allow Outcome builders subclasses use.
RSpec.describe Ai::Moderation::Rule do
  describe "abstractness" do
    it "cannot be instantiated directly (it is abstract)" do
      expect { described_class.new }.to raise_error(/abstract/)
    end

    it "raises on #moderate for a subclass that does not implement it" do
      incomplete = Class.new(described_class).new
      expect { incomplete.moderate("x", {}) }.to raise_error(NotImplementedError)
    end
  end

  describe "the Outcome builders" do
    # A minimal concrete rule exposing the protected builders for assertion.
    let(:rule) do
      Class.new(described_class) do
        def moderate(prompt, result)
          result["deny"] ? block("nope") : allow
        end
      end.new
    end

    it "#block builds a moderated Outcome carrying the reason" do
      outcome = rule.moderate("x", "deny" => true)
      expect(outcome.moderated?).to be(true)
      expect(outcome.reason).to eq("nope")
    end

    it "#allow builds a non-moderated Outcome with an empty reason" do
      outcome = rule.moderate("x", "deny" => false)
      expect(outcome.moderated?).to be(false)
      expect(outcome.reason).to eq("")
    end
  end
end
