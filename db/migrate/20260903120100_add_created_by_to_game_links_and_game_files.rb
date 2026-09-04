# typed: false

# Attribution for player contributions (Fizzy #18): who created each link/file,
# so the "players delete their own contributions" rule can identify ownership.
# The column is added nullable only long enough to backfill existing rows — all
# of which predate the feature and are GM contributions, stamped to the game's
# GM — then made NOT NULL, so every row (past and future) always names a real
# creator and no code has to defend against a null. New rows are stamped by the
# controllers at create time. Pages already carry authorship via their earliest
# PageVersion, so they need no column here.
class AddCreatedByToGameLinksAndGameFiles < ActiveRecord::Migration[8.1]
  def up
    add_reference :game_links, :created_by, foreign_key: { to_table: :users }
    add_reference :game_files, :created_by, foreign_key: { to_table: :users }

    backfill_to_game_master(:game_links)
    backfill_to_game_master(:game_files)

    change_column_null :game_links, :created_by_id, false
    change_column_null :game_files, :created_by_id, false
  end

  def down
    remove_reference :game_links, :created_by, foreign_key: { to_table: :users }
    remove_reference :game_files, :created_by, foreign_key: { to_table: :users }
  end

  private

  # Existing rows were all GM contributions; stamp each to its game's GM so the
  # delete-own rule reads real ownership rather than treating null as a special
  # case. Written in raw SQL against a correlated subquery so it does not depend
  # on model code that may change after this migration is written.
  def backfill_to_game_master(table)
    execute(<<~SQL.squish)
      UPDATE #{table}
      SET created_by_id = (
        SELECT gm.user_id FROM game_members gm
        WHERE gm.game_id = #{table}.game_id AND gm.role = 'game_master'
        LIMIT 1
      )
      WHERE created_by_id IS NULL
    SQL
  end
end
