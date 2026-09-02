require "rails_helper"

# Ai::Feature is the single source of truth for every AI feature the app has:
# its name, its funding level (game / app-infra), and whether it draws from a
# game's contribution pool. AiUsage validates against it and
# GameKeyAuthorization scopes to its pool-fundable members.
RSpec.describe Ai::Feature do
  describe "the registry" do
    it "declares scene_summary as a game-level, pool-fundable feature" do
      feature = described_class.fetch("scene_summary")

      expect(feature.level).to eq(:game)
      expect(feature.label).to eq("Scene summaries")
      expect(feature).to be_game_level
      expect(feature).to be_pool_fundable
    end

    it "declares character_portrait as a game-level, pool-fundable feature" do
      feature = described_class.fetch("character_portrait")

      expect(feature.level).to eq(:game)
      expect(feature.label).to eq("Character portraits")
      expect(feature).to be_game_level
      expect(feature).to be_pool_fundable
    end

    it "exposes the pool-fundable Features for the matrix columns" do
      expect(described_class.pool_fundable.map(&:name)).to eq([ "scene_summary", "character_portrait" ])
    end

    it "declares inbound_email as app-infra: not game-level, not pool-fundable" do
      feature = described_class.fetch("inbound_email")

      expect(feature.level).to eq(:app_infra)
      expect(feature).not_to be_game_level
      expect(feature).not_to be_pool_fundable
    end

    it "exposes every declared feature name" do
      expect(described_class.names).to include("scene_summary", "character_portrait", "inbound_email")
    end

    it "exposes only pool-fundable feature names for the authorization surface" do
      expect(described_class.pool_fundable_names).to include("scene_summary", "character_portrait")
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
end
