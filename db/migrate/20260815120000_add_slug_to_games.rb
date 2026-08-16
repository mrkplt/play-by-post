# typed: false

# Games are addressed in URLs by a slug instead of the raw numeric id: a
# name-derived, non-editable slug with a random alphanumeric suffix
# (games/dragons-of-icespire-peak-a1b2c3). The suffix guarantees uniqueness
# even when two games share a name. Existing games predate the column, so they
# are backfilled before the unique index is added so no NULLs collide.
class AddSlugToGames < ActiveRecord::Migration[8.1]
  def up
    add_column :games, :slug, :string

    say_with_time "Backfilling slug for existing games" do
      Game.reset_column_information
      # unscoped so soft-deleted games are backfilled too — the unique index
      # covers every row, and a purge sweep should not trip over a NULL.
      Game.unscoped.where(slug: nil).find_each do |game|
        game.update_column(:slug, GameSlug.build(game.name))
      end
    end

    change_column_null :games, :slug, false
    add_index :games, :slug, unique: true
  end

  def down
    remove_index :games, :slug
    remove_column :games, :slug
  end
end
