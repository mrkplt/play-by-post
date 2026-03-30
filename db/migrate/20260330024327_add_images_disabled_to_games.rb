class AddImagesDisabledToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :images_disabled, :boolean, default: false, null: false
  end
end
