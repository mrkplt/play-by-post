# typed: false

# Post/Scene inline image attachments were removed (a different image treatment
# is coming), so the per-game "images disabled" switch that gated them has no
# meaning anymore. Drop the column.
class RemoveImagesDisabledFromGames < ActiveRecord::Migration[8.1]
  def change
    remove_column :games, :images_disabled, :boolean, default: false, null: false
  end
end
