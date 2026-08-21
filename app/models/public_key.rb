# typed: true

# Public half of the general "seal a value to a public key, decrypt on the
# worker" custody primitive. Lives in the PRIMARY database — readable by the
# web tier so the browser can fetch the public key and encrypt a value to it
# client-side.
#
# The matching private key never lives here: see PrivateKey, which is stored
# encrypted-at-rest in a separate, worker-only database. This split is the
# point of the custody model — the web process that serves this record has no
# path, code or otherwise, to the private key.
#
# Unlike the AI-specific keypair this was extracted from, a PublicKey has no
# owner of its own and no sealed ciphertext of its own — both belong to
# EncryptedValue, the record 1:1 above it (EncryptedValue -1:1-> PublicKey
# -1:1-> PrivateKey). Every EncryptedValue gets a fresh, dedicated PublicKey
# (keypairs are free), so a PublicKey is only ever meaningful in the context
# of the one EncryptedValue that references it.
class PublicKey < ApplicationRecord
  extend T::Sig

  has_one :encrypted_value, inverse_of: :public_key, dependent: :destroy

  validates :public_key, presence: true
  validates :fingerprint, presence: true, uniqueness: true

  sig { returns(T.nilable(PrivateKey)) }
  def private_key
    PrivateKey.find_by(public_key_id: id)
  end
end
