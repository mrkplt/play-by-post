require "rails_helper"

RSpec.describe AiKeyResolver do
  # A real implementer of the KeySource interface, not a plain double: the
  # `key_source:` param is sig-typed to AiKeyResolver::KeySource, and
  # sorbet-runtime rejects an RSpec double against a concrete interface type
  # (see docs/TESTING_NOTES.md, "Sorbet + sorbet-runtime + specs"). Its methods
  # are still stubbed per-example via allow/have_received.
  class FakeKeySource
    include AiKeyResolver::KeySource

    def for_user(user) = "player-key"
    def for_game(game) = "game-key"
  end

  let(:key_source) { FakeKeySource.new }
  let(:resolver) { described_class.new(key_source: key_source) }

  # ai_key_present? is now derived from EncryptedValue's existence rather than
  # a plain attribute (see User#ai_key_present?/Game#ai_key_present?), so
  # AiKeyResolver's decision is exercised here by stubbing the predicate
  # directly instead of a factory attribute.
  def stub_key_present(record, present)
    allow(record).to receive(:ai_key_present?).and_return(present)
  end

  describe "#resolve" do
    it "uses the player's key when the player has one" do
      user = build_stubbed(:user).tap { |u| stub_key_present(u, true) }
      game = build_stubbed(:game).tap { |g| stub_key_present(g, true) }
      allow(key_source).to receive(:for_game).and_call_original

      expect(resolver.resolve(user: user, game: game)).to eq("player-key")
      expect(key_source).not_to have_received(:for_game)
    end

    it "falls back to the game's key when the player has none" do
      user = build_stubbed(:user).tap { |u| stub_key_present(u, false) }
      game = build_stubbed(:game).tap { |g| stub_key_present(g, true) }

      expect(resolver.resolve(user: user, game: game)).to eq("game-key")
    end

    it "asks the key source for the player's key, not the game's, when the player has one" do
      user = build_stubbed(:user).tap { |u| stub_key_present(u, true) }
      game = build_stubbed(:game).tap { |g| stub_key_present(g, true) }
      allow(key_source).to receive(:for_user).and_call_original

      resolver.resolve(user: user, game: game)

      expect(key_source).to have_received(:for_user).with(user)
    end

    it "asks the key source for the game's key when falling back" do
      user = build_stubbed(:user).tap { |u| stub_key_present(u, false) }
      game = build_stubbed(:game).tap { |g| stub_key_present(g, true) }
      allow(key_source).to receive(:for_game).and_call_original

      resolver.resolve(user: user, game: game)

      expect(key_source).to have_received(:for_game).with(game)
    end

    it "raises NoKeyAvailable when neither the player nor the game has a key" do
      user = build_stubbed(:user).tap { |u| stub_key_present(u, false) }
      game = build_stubbed(:game).tap { |g| stub_key_present(g, false) }

      expect { resolver.resolve(user: user, game: game) }
        .to raise_error(AiKeyResolver::NoKeyAvailable)
    end

    it "does not call the key source at all on refusal" do
      user = build_stubbed(:user).tap { |u| stub_key_present(u, false) }
      game = build_stubbed(:game).tap { |g| stub_key_present(g, false) }
      allow(key_source).to receive(:for_user).and_call_original
      allow(key_source).to receive(:for_game).and_call_original

      expect { resolver.resolve(user: user, game: game) }.to raise_error(AiKeyResolver::NoKeyAvailable)

      expect(key_source).not_to have_received(:for_user)
      expect(key_source).not_to have_received(:for_game)
    end
  end
end
