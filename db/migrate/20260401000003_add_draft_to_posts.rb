class AddDraftToPosts < ActiveRecord::Migration[8.1]
  def change
    change_column_null :posts, :content, true
    add_column :posts, :draft, :boolean, default: false, null: false
  end
end
