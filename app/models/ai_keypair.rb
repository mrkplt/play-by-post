# typed: true

# Public half of a user's BYOK (bring-your-own OpenRouter API key) custody
# keypair. Lives in the PRIMARY database — readable by the web tier so the
# browser can fetch the public key and encrypt a BYOK key to it client-side.
#
# The matching private key never lives here: see AiPrivateKey, which is
# stored encrypted-at-rest in a separate, worker-only database. This split is
# the point of the custody model — the web process that serves this record
# has no path, code or otherwise, to the private key.
class AiKeypair < ApplicationRecord
  extend T::Sig

  belongs_to :user

  validates :public_key, presence: true
  validates :fingerprint, presence: true, uniqueness: true
  validates :user_id, uniqueness: true

  sig { returns(T.nilable(AiPrivateKey)) }
  def private_key
    AiPrivateKey.find_by(ai_keypair_id: id)
  end
end
