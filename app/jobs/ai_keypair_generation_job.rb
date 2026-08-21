# typed: true

# Generates a fresh BYOK custody keypair for an owner (User or Game) and
# writes both halves — see AiKeypairs::KeypairGenerator's class comment for
# the custody model this splits across two databases.
#
# Deliberately generates the key material INSIDE #perform, on whichever
# process actually runs this job, rather than accepting PEM strings as job
# arguments. Solid Queue jobs are serialized into the `queue` Solid Queue
# database (config/database.yml `production.queue`), which lives on the
# SAME shared volume as the primary database (docker-compose.yml `dbdata`,
# mounted on both `web` and `worker`) — not the worker-only `ai_keys` volume.
# Passing a private key PEM as a job argument would put it in plaintext
# somewhere `web` can read, defeating the entire custody split documented on
# AiPrivateKey and config/initializers/ai_private_key_encryption.rb. Taking
# only `owner_type`/`owner_id` means no key material is ever serialized
# outside the process that generates it.
#
# In production this job only actually completes on `worker`: AiPrivateKey's
# `ai_keys` database connection and its Active Record Encryption credential
# are both absent on `web` (AiPrivateKeyEncryption::UnavailableKeyProvider),
# so a `create!` here raises on `web` and the job (if ever misrouted there)
# would fail loudly rather than silently persisting unencrypted. Solid Queue
# is configured to run only in the dedicated `worker` container (see
# docs/CONFIGURATION.md "do NOT set" `SOLID_QUEUE_IN_PUMA`), so this is the
# expected/only place `#perform` runs to completion.
class AiKeypairGenerationJob < ApplicationJob
  extend T::Sig

  queue_as :default

  sig { params(owner_type: String, owner_id: Integer).void }
  def perform(owner_type:, owner_id:)
    return if AiKeypair.exists?(owner_type: owner_type, owner_id: owner_id)

    generated = AiKeypairs::KeypairGenerator.call

    keypair = AiKeypair.create!(
      owner_type: owner_type,
      owner_id: owner_id,
      public_key: generated.public_key_pem,
      fingerprint: generated.fingerprint
    )

    AiPrivateKey.create!(ai_keypair_id: keypair.id, encrypted_private_key: generated.private_key_pem)
  end
end
