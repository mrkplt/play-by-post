class CreateNotebookEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :notebook_entries do |t|
      t.references :game, null: false, foreign_key: true
      # Globally-unique, non-editable 16-char alphanumeric slug: the entry's URL
      # id under games/:game_id/notebook_entries/:slug. Generated on create,
      # never changes.
      t.string :slug, null: false
      t.string :title, null: false
      t.text :body
      # Kanban lane: new / expand / done / discard. See NotebookEntry::STATUSES.
      t.string :status, null: false, default: "new"
      # Set when this entry has been promoted to a full game Page; nil until then.
      t.references :promoted_page, foreign_key: { to_table: :pages }, null: true

      t.timestamps
    end

    add_index :notebook_entries, :slug, unique: true
  end
end
