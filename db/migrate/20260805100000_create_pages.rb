class CreatePages < ActiveRecord::Migration[8.1]
  def change
    create_table :pages do |t|
      t.references :game, null: false, foreign_key: true
      # Globally-unique, non-editable 16-char alphanumeric slug: the page's URL
      # id under games/:game_id/pages/:slug. Generated on create, never changes.
      t.string :slug, null: false
      t.string :title, null: false
      t.text :body

      t.timestamps
    end

    add_index :pages, :slug, unique: true
  end
end
