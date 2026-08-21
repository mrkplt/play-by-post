class CreatePublicKeys < ActiveRecord::Migration[8.1]
  # The public half of a general "seal a value to a public key, decrypt on the
  # worker" custody primitive — see app/models/public_key.rb. Generalized out
  # of the old AiKeypair (which conflated this crypto primitive with its first
  # consumer, the BYOK OpenRouter key). Lives in the PRIMARY database —
  # readable by the web tier so the browser can fetch the public key and
  # encrypt a value to it client-side. No owner here (unlike the old
  # AiKeypair): ownership belongs to the consumer record (EncryptedValue),
  # since a PublicKey now exists purely to pair 1:1 with one EncryptedValue
  # and one PrivateKey.
  def change
    create_table :public_keys do |t|
      # PEM-encoded RSA public key (RSA-OAEP-256, 2048-bit). See
      # app/services/crypto/crypto_service.rb for the envelope format this key
      # is used with.
      t.text :public_key, null: false
      # SHA-256 fingerprint of the DER-encoded public key, hex-encoded. Lets
      # the browser/UI confirm which key it is encrypting against without
      # parsing PEM.
      t.string :fingerprint, null: false

      t.timestamps
    end

    add_index :public_keys, :fingerprint, unique: true
  end
end
