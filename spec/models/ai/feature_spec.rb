require "rails_helper"

# Ai::Feature is the single source of truth for every AI feature the app has:
# its name, its funding level (game / personal / app-infra), and whether it
# draws from a game's contribution pool. AiUsage validates against it and
# GameKeyAuthorization scopes to its pool-fundable members.
RSpec.describe Ai::Feature do
  describe "the registry" do
    it "declares scene_summary as a game-level, pool-fundable feature" do
      feature = described_class.fetch("scene_summary")

      expect(feature.level).to eq(:game)
      expect(feature).to be_game_level
      expect(feature).to be_pool_fundable
    end

    it "declares inbound_email as app-infra: neither game nor personal, not pool-fundable" do
      feature = described_class.fetch("inbound_email")

      expect(feature.level).to eq(:app_infra)
      expect(feature).not_to be_game_level
      expect(feature).not_to be_personal_level
      expect(feature).not_to be_pool_fundable
    end

    it "exposes every declared feature name" do
      expect(described_class.names).to include("scene_summary", "inbound_email")
    end

    it "exposes only pool-fundable feature names for the authorization surface" do
      expect(described_class.pool_fundable_names).to include("scene_summary")
      expect(described_class.pool_fundable_names).not_to include("inbound_email")
    end
  end

  describe ".fetch" do
    it "returns the feature for a known name" do
      expect(described_class.fetch("scene_summary")).to be_a(described_class)
    end

    it "raises for an unknown name (fail-closed)" do
      expect { described_class.fetch("nope") }.to raise_error(KeyError)
    end
  end

  describe ".known?" do
    it "is true for a declared feature" do
      expect(described_class.known?("scene_summary")).to be(true)
    end

    it "is false for an undeclared feature" do
      expect(described_class.known?("nope")).to be(false)
    end
  end

  describe ".pool_fundable?" do
    it "is true for a game-level feature" do
      expect(described_class.pool_fundable?("scene_summary")).to be(true)
    end

    it "is false for an app-infra feature" do
      expect(described_class.pool_fundable?("inbound_email")).to be(false)
    end

    it "is false for an unknown feature" do
      expect(described_class.pool_fundable?("nope")).to be(false)
    end
  end

  describe "level predicates" do
    it "personal_level? is true only for a personal feature" do
      # No personal feature ships yet (portraits #19 will add one); assert the
      # predicate is wired by confirming a game feature is not personal.
      expect(described_class.fetch("scene_summary")).not_to be_personal_level
    end
  end
end
