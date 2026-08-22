require "rails_helper"

RSpec.describe AiKeyResolver do
  # A real implementer of the KeySource interface, not a plain double: the
  # `key_source:` param is sig-typed to AiKeyResolver::KeySource, and
  # sorbet-runtime rejects an RSpec double against a concrete interface type
  # (see docs/TESTING_NOTES.md, "Sorbet + sorbet-runtime + specs").
  class FakeKeySource
    include AiKeyResolver::KeySource

    def for_user(user) = "key-for-#{user.id}"
  end

  let(:key_source) { FakeKeySource.new }
  let(:resolver) { described_class.new(key_source: key_source) }

  describe "#candidates" do
    it "returns a candidate per available authorization for the feature" do
      allow_any_instance_of(User).to receive(:ai_key_present?).and_return(true)
      game = create(:game)
      a = create(:game_key_authorization, game: game, feature: "scene_summary")
      b = create(:game_key_authorization, game: game, feature: "scene_summary")

      candidates = resolver.candidates(feature: "scene_summary", game: game)

      expect(candidates.map(&:user)).to contain_exactly(a.user, b.user)
    end

    it "excludes an authorization whose owner no longer has a key" do
      allow_any_instance_of(User).to receive(:ai_key_present?).and_return(true)
      game = create(:game)
      keyed = create(:game_key_authorization, game: game, feature: "scene_summary")
      create(:game_key_authorization, game: game, feature: "scene_summary")

      # Only `keyed`'s owner keeps a key.
      allow_any_instance_of(User).to receive(:ai_key_present?) { |u| u == keyed.user }

      candidates = resolver.candidates(feature: "scene_summary", game: game)
      expect(candidates.map(&:user)).to eq([ keyed.user ])
    end

    it "raises NoKeyAvailable when the pool is empty" do
      game = create(:game)

      expect { resolver.candidates(feature: "scene_summary", game: game) }
        .to raise_error(AiKeyResolver::NoKeyAvailable)
    end

    it "resolves a candidate's key lazily through the key source" do
      allow_any_instance_of(User).to receive(:ai_key_present?).and_return(true)
      game = create(:game)
      auth = create(:game_key_authorization, game: game, feature: "scene_summary")

      candidate = resolver.candidates(feature: "scene_summary", game: game).first
      expect(candidate.key).to eq("key-for-#{auth.user.id}")
    end
  end

  # The pool decrements on failure: the caller pops candidates, and a failed
  # key is simply removed from the array (there is no re-offer). This is the
  # tested property — not the random draw order.
  describe "pop-with-failover (caller contract)" do
    it "hands back an array the caller can pop to exhaustion, each key once" do
      allow_any_instance_of(User).to receive(:ai_key_present?).and_return(true)
      game = create(:game)
      create(:game_key_authorization, game: game, feature: "scene_summary")
      create(:game_key_authorization, game: game, feature: "scene_summary")

      candidates = resolver.candidates(feature: "scene_summary", game: game)

      seen = []
      seen << candidates.pop.user until candidates.empty?

      expect(seen.size).to eq(2)
      expect(seen.uniq.size).to eq(2)
    end
  end
end
