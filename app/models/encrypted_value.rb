# typed: true

# The consumer-facing record of the custody primitive: "seal THIS value, of
# THIS type, for THIS owner." Owns the polymorphic owner and the sealed
# ciphertext that used to live directly on the old AiKeypair; the crypto
# custody split (public key readable by web, private key worker-only) lives
# one level down, in PublicKey/PrivateKey.
#
#   EncryptedValue (owner, value_type, sealed_value) -1:1-> PublicKey -1:1-> PrivateKey
#
# Every EncryptedValue has its OWN dedicated PublicKey/PrivateKey pair —
# keypairs are free, so there is no reuse of one keypair across values. An
# owner can hold MANY EncryptedValues, one per distinct `value_type`
# (uniqueness is scoped to [owner, value_type], not to the owner alone) — e.g.
# a User could in principle have separate EncryptedValues for
# "openrouter_key" and some future secret, each with its own keypair.
#
# `value_type` is a plain string tag naming what the sealed value is for (see
# Profiles::ByokKeysController for the current "openrouter_key" consumer).
# Deliberately NOT named `type` — a bare `type` column is reserved by Active
# Record for single-table inheritance.
class EncryptedValue < ApplicationRecord
  extend T::Sig

  # A key is real money, and only a person can own money — so an EncryptedValue
  # is owned by a User, never a Game. A game does not own a key; people own keys
  # and authorize a game to *use* them (see GameKeyAuthorization). The column
  # stays polymorphic in shape (owner_type/owner_id) for the custody primitive's
  # generality, but the association is pinned to User.
  belongs_to :owner, polymorphic: true, inverse_of: false
  belongs_to :public_key, inverse_of: :encrypted_value

  validates :owner_type, inclusion: { in: %w[User] }

  validates :value_type, presence: true
  validates :owner_id, uniqueness: { scope: %i[owner_type value_type] }

  sig { returns(T.nilable(PrivateKey)) }
  def private_key
    T.must(public_key).private_key
  end

  # The stored envelope parsed into a Blob, or nil when no value has been sealed.
  sig { returns(T.nilable(Crypto::Blob)) }
  def sealed_blob
    raw = sealed_value
    return nil if raw.blank?

    Crypto::Blob.from_json(raw)
  end
end
