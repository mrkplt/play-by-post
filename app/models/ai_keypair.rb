# typed: true

# Public half of a BYOK (bring-your-own OpenRouter API key) custody keypair,
# owned by either a User (a player's key) or a Game (a GM-set game-level
# fallback). Lives in the PRIMARY database — readable by the web tier so the
# browser can fetch the public key and encrypt a BYOK key to it client-side.
#
# The matching private key never lives here: see AiPrivateKey, which is
# stored encrypted-at-rest in a separate, worker-only database. This split is
# the point of the custody model — the web process that serves this record
# has no path, code or otherwise, to the private key.
#
# `sealed_key` holds the browser-produced envelope (AiKeypairs::Blob JSON) of
# the owner's BYOK key, persisted so a background job can resolve it without
# the browser present. It is null until the owner supplies a key.
class AiKeypair < ApplicationRecord
  extend T::Sig

  belongs_to :owner, polymorphic: true

  validates :public_key, presence: true
  validates :fingerprint, presence: true, uniqueness: true
  validates :owner_id, uniqueness: { scope: :owner_type }

  sig { returns(T.nilable(AiPrivateKey)) }
  def private_key
    AiPrivateKey.find_by(ai_keypair_id: id)
  end

  # The stored envelope parsed into a Blob, or nil when no key has been sealed.
  sig { returns(T.nilable(AiKeypairs::Blob)) }
  def sealed_blob
    raw = sealed_key
    return nil if raw.blank?

    AiKeypairs::Blob.from_json(raw)
  end
end
