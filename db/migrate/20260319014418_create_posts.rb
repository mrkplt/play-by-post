class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.references :scene, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.boolean :is_ooc, null: false, default: false
      t.datetime :last_edited_at

      t.timestamps
    end
  end
end
