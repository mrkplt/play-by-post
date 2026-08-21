class CreateEncryptedValues < ActiveRecord::Migration[8.1]
  # The record a consumer creates: "seal THIS value, of THIS type, for THIS
  # owner." Owns the relationship EncryptedValue (owner, type, sealed
  # ciphertext) -1:1-> PublicKey -1:1-> PrivateKey. Replaces the polymorphic
  # `owner`/`sealed_key` columns that used to live directly on AiKeypair — see
  # app/models/encrypted_value.rb.
  #
  # An owner can have MANY EncryptedValues (of different types), each with its
  # own dedicated keypair — keypairs are free, so every value gets a fresh
  # one rather than reusing one keypair per owner. Uniqueness is therefore
  # scoped to [owner, type], not to owner alone.
  def change
    create_table :encrypted_values do |t|
      t.references :owner, polymorphic: true, null: false
      # What this value is for, e.g. "openrouter_key" — lets one owner hold
      # several distinct sealed values, each with its own keypair. Named
      # `value_type`, not `type`: a bare `type` column is reserved by Active
      # Record for single-table inheritance and would make EncryptedValue an
      # STI base class instead of a plain attribute.
      t.string :value_type, null: false
      # The browser-sealed ciphertext envelope: JSON { wrapped_key, iv,
      # ciphertext } (see Crypto::Blob / Crypto::CryptoService). Null until
      # the owner supplies a value; an EncryptedValue can exist (public key
      # published) before a value is sealed.
      t.text :sealed_value, null: true
      t.references :public_key, null: false, foreign_key: true, index: { unique: true }

      t.timestamps
    end

    add_index :encrypted_values, %i[owner_type owner_id value_type], unique: true, name: "index_encrypted_values_on_owner_and_type"
  end
end
