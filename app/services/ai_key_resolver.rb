# typed: strict

# Decides whose OpenRouter API key funds a player-facing AI call, and hands
# back the decrypted key string. Resolution order is fixed: player key → game
# key → refuse. There is no app-level key fallback for player-facing AI (the
# app's own OpenRouter key stays reserved for app infra, e.g. inbound-email
# extraction — a caller entirely outside this class).
#
# This class owns only the *decision* of whose key wins. It does not know how
# a key is stored, encrypted, or decrypted — that is the injected KeySource's
# job, built and owned separately (see KeySource below). AiKeyResolver reads
# only the presence seam on User/Game (#ai_key_present?, backed by the opaque
# `ai_key_reference` handle column) to decide *whose* key to ask for, then
# asks the KeySource to actually resolve that handle to a usable key.
class AiKeyResolver
  extend T::Sig

  # Raised when neither the player nor the game has a BYOK key configured.
  # There is no further fallback — the caller must treat the AI feature as
  # unavailable, not silently substitute the app's own key.
  class NoKeyAvailable < StandardError; end

  # The port this class depends on. Implement and inject a KeySource to
  # compose AiKeyResolver with the actual encrypted-key storage/crypto
  # (built separately — see AiKeyResolver's class comment):
  #
  #   for_user(user) -> String  — the decrypted OpenRouter key for this user's
  #                                ai_key_reference. Only called when
  #                                user.ai_key_present? is true.
  #   for_game(game) -> String  — the decrypted OpenRouter key for this game's
  #                                ai_key_reference. Only called when
  #                                game.ai_key_present? is true.
  #
  # Both methods are expected to return a non-empty key string when the
  # corresponding *_present? predicate was true; AiKeyResolver does not
  # revalidate the result. Any lookup/decrypt failure is the KeySource's to
  # raise — AiKeyResolver does not rescue it.
  module KeySource
    extend T::Sig
    extend T::Helpers

    interface!

    sig { abstract.params(user: User).returns(String) }
    def for_user(user); end

    sig { abstract.params(game: Game).returns(String) }
    def for_game(game); end
  end

  sig { params(key_source: KeySource).void }
  def initialize(key_source:)
    @key_source = key_source
  end

  # Resolves the OpenRouter key that funds an AI call made by `user` within
  # `game`: the player's own key first, then the game's key, else raises
  # NoKeyAvailable.
  sig { params(user: User, game: Game).returns(String) }
  def resolve(user:, game:)
    return @key_source.for_user(user) if user.ai_key_present?
    return @key_source.for_game(game) if game.ai_key_present?

    raise NoKeyAvailable, "No BYOK OpenRouter key available for user=#{user.id} game=#{game.id}"
  end
end
