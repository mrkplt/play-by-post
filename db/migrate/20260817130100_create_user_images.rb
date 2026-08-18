# typed: false

# A user's avatar library, identical in shape to character_images: one row per
# uploaded square-cropped image, `current` marking the active avatar. The blob is
# an Active Storage attachment.
class CreateUserImages < ActiveRecord::Migration[8.1]
  def change
    create_table :user_images do |t|
      t.references :user, null: false, foreign_key: true
      t.boolean :current, null: false, default: false

      t.timestamps
    end

    add_index :user_images, [ :user_id, :current ]
  end
end
