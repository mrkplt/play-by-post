class CreateAiPrivateKeys < ActiveRecord::Migration[8.1]
  def change
    # No foreign_key: true — ai_keypairs lives in a different physical
    # database (the primary db), so SQLite cannot enforce a cross-database FK.
    # ai_keypair_id is an application-level reference only, validated in
    # AiPrivateKey.
    create_table :ai_private_keys do |t|
      t.bigint :ai_keypair_id, null: false
      # PEM-encoded RSA private key, encrypted at rest via Active Record
      # Encryption (see app/models/ai_private_key.rb and
      # config/initializers/ai_private_key_encryption.rb). Column is `text`
      # because ciphertext (Base64-serialized) is longer than the plaintext PEM.
      t.text :encrypted_private_key, null: false

      t.timestamps
    end

    add_index :ai_private_keys, :ai_keypair_id, unique: true
  end
end
