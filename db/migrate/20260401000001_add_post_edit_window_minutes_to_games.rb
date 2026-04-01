class AddPostEditWindowMinutesToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :post_edit_window_minutes, :integer
  end
end
