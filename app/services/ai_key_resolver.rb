# typed: strict

# Decides WHICH people's OpenRouter keys may fund a game-level AI call, and in
# what (random) order the worker should try them. It does NOT make the call —
# it hands the generation service a shuffled pool of candidate keys to spend,
# and that service tries them with failover (see SceneSummaryService).
#
# Keys are person-owned (EncryptedValue, owned by a User). A game funds a
# game-level feature from its POOL: the people who authorized their key to fund
# that feature for that game (GameKeyAuthorization) and still have a key. The
# order is random with failover — but the property that matters is that the
# pool DECREMENTS on failure: the caller pops candidates one at a time, and a
# failed key is simply gone (see #candidates returning a shuffled array the
# caller pops).
#
# This class owns only the *decision* of whose keys are in the pool and the
# shuffle. It does not know how a key is stored/encrypted/decrypted — that is
# the injected KeySource's job (Crypto::StoredKeySource, worker-only). A
# Candidate decrypts lazily, so only a key actually reached in the failover
# walk is ever decrypted.
class AiKeyResolver
  extend T::Sig

  # Raised when a game has no available key to fund the feature — nobody has
  # authorized a present key for it. There is no app-key fallback for a
  # player-facing AI call.
  class NoKeyAvailable < StandardError; end

  # One fundable key in the pool: the person who owns it, and their decrypted
  # key resolved lazily via the KeySource (only when the failover walk actually
  # reaches this candidate).
  class Candidate
    extend T::Sig

    sig { returns(User) }
    attr_reader :user

    sig { params(user: User, key_source: KeySource).void }
    def initialize(user:, key_source:)
      @user = user
      @key_source = key_source
    end

    sig { returns(String) }
    def key
      @key_source.for_user(user)
    end
  end

  # The port this class depends on: resolve a User to their decrypted
  # "openrouter_key". Implemented by Crypto::StoredKeySource (worker-only). Only
  # called for a user whose ai_key_present? was true when the pool was built.
  module KeySource
    extend T::Sig
    extend T::Helpers

    interface!

    sig { abstract.params(_user: User).returns(String) }
    def for_user(_user); end
  end

  sig { params(key_source: KeySource).void }
  def initialize(key_source:)
    @key_source = key_source
  end

  # The shuffled pool of candidate keys that may fund `feature` for `game`,
  # for the caller to pop with failover. Raises NoKeyAvailable when the pool is
  # empty (nobody authorized a present key), so the caller never walks an empty
  # array into a silent no-op.
  sig { params(feature: String, game: Game).returns(T::Array[Candidate]) }
  def candidates(feature:, game:)
    authorizations = GameKeyAuthorization.available_for(game: game, feature: feature)
    raise NoKeyAvailable, "No BYOK OpenRouter key available for feature=#{feature} game=#{game.id}" if authorizations.empty?

    authorizations.shuffle.map { |auth| Candidate.new(user: T.must(auth.user), key_source: @key_source) }
  end
end
