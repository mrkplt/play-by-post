class MakeAiKeypairsOwnerPolymorphicAndAddSealedKey < ActiveRecord::Migration[8.1]
  # An AiKeypair belongs to either a User (a player's BYOK key) or a Game (a
  # game-level fallback key set by the GM), so the resolver can fall back
  # player-key -> game-key. Ownership becomes polymorphic; the sealed BYOK key
  # envelope (browser-produced, worker-decryptable) is stored alongside the
  # public key so a background job can resolve it without the browser present.
  def up
    # One keypair per owner — the unique composite index is created by
    # add_reference's `index:` option (a separate add_index would collide).
    add_reference :ai_keypairs, :owner, polymorphic: true, null: true,
                  index: { unique: true, name: "index_ai_keypairs_on_owner" }

    # No production rows yet; backfill the one shape that existed (user-owned)
    # for safety, then drop the old user_id column and enforce presence.
    execute <<~SQL
      UPDATE ai_keypairs
      SET owner_type = 'User', owner_id = user_id
      WHERE user_id IS NOT NULL
    SQL

    remove_reference :ai_keypairs, :user, foreign_key: true, index: true

    change_column_null :ai_keypairs, :owner_type, false
    change_column_null :ai_keypairs, :owner_id, false

    # The browser-sealed BYOK key: JSON envelope { wrapped_key, iv, ciphertext }
    # (see AiKeypairs::Blob / CryptoService). Null until the owner supplies a
    # key; a keypair can exist (public key published) before a key is sealed.
    add_column :ai_keypairs, :sealed_key, :text, null: true
  end

  def down
    remove_column :ai_keypairs, :sealed_key
    remove_index :ai_keypairs, name: "index_ai_keypairs_on_owner"
    add_reference :ai_keypairs, :user, foreign_key: true, index: { unique: true }
    execute <<~SQL
      UPDATE ai_keypairs SET user_id = owner_id WHERE owner_type = 'User'
    SQL
    remove_reference :ai_keypairs, :owner, polymorphic: true
  end
end
