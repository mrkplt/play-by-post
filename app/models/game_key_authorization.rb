# typed: true

# One person's consent that their personal OpenRouter key may fund one
# pool-fundable feature for one game — the unit of the "contribution pool".
#
# A game does NOT own a key; people do (see EncryptedValue, owned by a User).
# A member authorizes their OWN key to fund specific features for specific
# games, one row per [game, user, feature]. The pool a game draws from for a
# feature is `available_for` — the authorizations whose owner still has a key.
#
# Consent lives here, on the web side: the web tier records/enumerates who is
# available; only the worker ever decrypts and spends (Crypto::StoredKeySource
# / PrivateKey are worker-only).
class GameKeyAuthorization < ApplicationRecord
  extend T::Sig

  belongs_to :game
  belongs_to :user

  # Only pool-fundable (game-level) features can be authorized — a personal or
  # app-infra feature never draws from a game's pool (see Ai::Feature).
  validates :feature, inclusion: { in: Ai::Feature.pool_fundable_names }
  validates :user_id, uniqueness: { scope: %i[game_id feature] }

  # You can only authorize a key you actually have. Checked on the record's
  # user so offering a key you never sealed is rejected in-band.
  validate :user_has_key, on: :create

  # The available pool for a game+feature: every authorization for that pair
  # whose owner still has a sealed key. `ai_key_present?` is a per-owner
  # predicate (not a column), so this filters in Ruby after loading the small
  # per-game set.
  sig { params(game: Game, feature: String).returns(T::Array[GameKeyAuthorization]) }
  def self.available_for(game:, feature:)
    where(game: game, feature: feature).select { |auth| T.must(auth.user).ai_key_present? }
  end

  private

  sig { void }
  def user_has_key
    return if user&.ai_key_present?

    errors.add(:user, "must have a BYOK OpenRouter key to authorize it for a game")
  end
end
