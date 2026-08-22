# typed: true

# Creates an EncryptedValue shell — a fresh dedicated custody keypair plus the
# owning EncryptedValue row — for a User owner and a value_type, and writes
# both keypair halves. Keys are person-owned (a game does not own a key; see
# EncryptedValue / GameKeyAuthorization). See Crypto::KeypairGenerator's class
# comment for the custody model this splits across two databases.
#
# Deliberately generates the key material INSIDE #perform, on whichever
# process actually runs this job, rather than accepting PEM strings as job
# arguments. Solid Queue jobs are serialized into the `queue` Solid Queue
# database (config/database.yml `production.queue`), which lives on the
# SAME shared volume as the primary database (docker-compose.yml `dbdata`,
# mounted on both `web` and `worker`) — not the worker-only `ai_keys` volume.
# Passing a private key PEM as a job argument would put it in plaintext
# somewhere `web` can read, defeating the entire custody split documented on
# PrivateKey and config/initializers/private_key_encryption.rb. Taking only
# `owner_type`/`owner_id`/`value_type` means no key material is ever
# serialized outside the process that generates it.
#
# In production this job only actually completes on `worker`: PrivateKey's
# `ai_keys` database connection and its Active Record Encryption credential
# are both absent on `web` (PrivateKeyEncryption::UnavailableKeyProvider), so
# a `create!` here raises on `web` and the job (if ever misrouted there)
# would fail loudly rather than silently persisting unencrypted. Solid Queue
# is configured to run only in the dedicated `worker` container (see
# docs/CONFIGURATION.md "do NOT set" `SOLID_QUEUE_IN_PUMA`), so this is the
# expected/only place `#perform` runs to completion.
class KeypairGenerationJob < ApplicationJob
  extend T::Sig

  queue_as :default

  sig { params(owner_type: String, owner_id: Integer, value_type: String).void }
  def perform(owner_type:, owner_id:, value_type:)
    return if EncryptedValue.exists?(owner_type: owner_type, owner_id: owner_id, value_type: value_type)

    generated = Crypto::KeypairGenerator.call

    public_key = PublicKey.create!(public_key: generated.public_key_pem, fingerprint: generated.fingerprint)

    EncryptedValue.create!(
      owner_type: owner_type,
      owner_id: owner_id,
      value_type: value_type,
      public_key: public_key
    )

    PrivateKey.create!(public_key_id: public_key.id, encrypted_private_key: generated.private_key_pem)
  end
end
