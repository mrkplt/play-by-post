# typed: true

# Private half of the general custody keypair (see PublicKey). Stored in the
# SEPARATE `ai_keys` database (config/database.yml), which in production is
# mounted on a worker-only volume (docker-compose.yml `worker.volumes` — not
# present on `web` at all). `connects_to` (via KeysRecord) is what makes this
# class read/write that database instead of the primary one; every query
# against PrivateKey goes through this connection regardless of which process
# runs it, but only the worker process has a filesystem path to the file it
# points at in production.
#
# `encrypted_private_key` is additionally encrypted at rest via Active Record
# Encryption, keyed by a bespoke credential (config/ai_private_keys.yml.enc —
# filename kept as-is, see config/initializers/private_key_encryption.rb) that
# is itself only supplied to the worker. So a copy of this database's file
# alone (e.g. a stray backup) is not enough to recover a key; the encryption
# credential is a second, independently-held secret.
#
# There is no belongs_to :public_key — PublicKey lives in a different physical
# database, and ActiveRecord associations do not span `connects_to`
# boundaries. PublicKey#private_key and Crypto::CryptoService look this row up
# by public_key_id instead.
class PrivateKey < KeysRecord
  extend T::Sig

  encrypts :encrypted_private_key, key_provider: PrivateKeyEncryption::KEY_PROVIDER

  validates :public_key_id, presence: true, uniqueness: true
  validates :encrypted_private_key, presence: true

  sig { returns(T.nilable(PublicKey)) }
  def public_key
    PublicKey.find_by(id: public_key_id)
  end
end
