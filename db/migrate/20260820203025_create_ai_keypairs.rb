class CreateAiKeypairs < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_keypairs do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      # PEM-encoded RSA public key (RSA-OAEP-256, 2048-bit). Readable by the
      # web tier — the browser fetches it to encrypt a BYOK key client-side.
      # See app/services/ai_keypairs/crypto_service.rb for the blob format
      # this key is used with.
      t.text :public_key, null: false
      # SHA-256 fingerprint of the DER-encoded public key, hex-encoded. Lets
      # the browser/UI confirm which key it is encrypting against without
      # parsing PEM.
      t.string :fingerprint, null: false

      t.timestamps
    end

    add_index :ai_keypairs, :fingerprint, unique: true
  end
end
