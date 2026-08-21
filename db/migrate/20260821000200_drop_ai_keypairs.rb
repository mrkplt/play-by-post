class DropAiKeypairs < ActiveRecord::Migration[8.1]
  # Replaces the AiKeypair table with the generalized PublicKey +
  # EncryptedValue split (see CreatePublicKeys/CreateEncryptedValues). This
  # branch has no production data and is not yet merged, so there is nothing
  # to backfill — the old table is simply dropped.
  def up
    drop_table :ai_keypairs
  end

  def down
    create_table :ai_keypairs do |t|
      t.text :public_key, null: false
      t.string :fingerprint, null: false
      t.text :sealed_key
      t.references :owner, polymorphic: true, null: false, index: { unique: true, name: "index_ai_keypairs_on_owner" }

      t.timestamps
    end

    add_index :ai_keypairs, :fingerprint, unique: true
  end
end
