# typed: false

# A character's portrait library: each row is one uploaded, square-cropped image;
# the `current` flag marks the one shown as the character's portrait. At most one
# row per character is current (enforced in the model's make_current!). The blob
# itself is an Active Storage attachment, not a column.
class CreateCharacterImages < ActiveRecord::Migration[8.1]
  def change
    create_table :character_images do |t|
      t.references :character, null: false, foreign_key: true
      t.boolean :current, null: false, default: false

      t.timestamps
    end

    add_index :character_images, [ :character_id, :current ]
  end
end
