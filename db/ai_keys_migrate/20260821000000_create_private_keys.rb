class CreatePrivateKeys < ActiveRecord::Migration[8.1]
  # Replaces ai_private_keys with the generalized PrivateKey — see
  # app/models/private_key.rb. No production data on this branch, so the old
  # table (created by db/ai_keys_migrate/20260820203042_create_ai_private_keys.rb)
  # is dropped and recreated rather than altered/backfilled.
  #
  # No foreign_key: true on public_key_id — public_keys lives in a different
  # physical database (the primary db), so SQLite cannot enforce a
  # cross-database FK. public_key_id is an application-level reference only,
  # validated in PrivateKey.
  def up
    drop_table :ai_private_keys

    create_table :private_keys do |t|
      t.bigint :public_key_id, null: false
      # PEM-encoded RSA private key, encrypted at rest via Active Record
      # Encryption (see app/models/private_key.rb and
      # config/initializers/private_key_encryption.rb). Column is `text`
      # because ciphertext (Base64-serialized) is longer than the plaintext PEM.
      t.text :encrypted_private_key, null: false

      t.timestamps
    end

    add_index :private_keys, :public_key_id, unique: true
  end

  def down
    drop_table :private_keys

    create_table :ai_private_keys do |t|
      t.bigint :ai_keypair_id, null: false
      t.text :encrypted_private_key, null: false

      t.timestamps
    end

    add_index :ai_private_keys, :ai_keypair_id, unique: true
  end
end
