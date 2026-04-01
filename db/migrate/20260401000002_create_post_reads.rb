class CreatePostReads < ActiveRecord::Migration[8.1]
  def change
    create_table :post_reads do |t|
      t.references :post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :read_at, null: false

      t.timestamps
    end

    add_index :post_reads, [ :post_id, :user_id ], unique: true
  end
end
