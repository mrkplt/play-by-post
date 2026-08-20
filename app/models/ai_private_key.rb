# typed: true

# Private half of a user's BYOK custody keypair. Stored in the SEPARATE
# `ai_keys` database (config/database.yml), which in production is mounted on
# a worker-only volume (docker-compose.yml `worker.volumes` — not present on
# `web` at all). `connects_to` below is what makes this class read/write that
# database instead of the primary one; every query against AiPrivateKey goes
# through this connection regardless of which process runs it, but only the
# worker process has a filesystem path to the file it points at in production.
#
# `encrypted_private_key` is additionally encrypted at rest via Active Record
# Encryption, keyed by a bespoke credential (config/ai_private_keys.yml.enc)
# that is itself only supplied to the worker — see
# config/initializers/ai_private_key_encryption.rb. So a copy of this
# database's file alone (e.g. a stray backup) is not enough to recover a key;
# the encryption credential is a second, independently-held secret.
#
# There is no belongs_to :ai_keypair — AiKeypair lives in a different
# physical database, and ActiveRecord associations do not span
# `connects_to` boundaries. AiKeypair#private_key and
# AiKeypairs::CryptoService look this row up by ai_keypair_id instead.
class AiPrivateKey < AiKeysRecord
  extend T::Sig

  encrypts :encrypted_private_key, key_provider: AiPrivateKeyEncryption::KEY_PROVIDER

  validates :ai_keypair_id, presence: true, uniqueness: true
  validates :encrypted_private_key, presence: true

  sig { returns(T.nilable(AiKeypair)) }
  def ai_keypair
    AiKeypair.find_by(id: ai_keypair_id)
  end
end
