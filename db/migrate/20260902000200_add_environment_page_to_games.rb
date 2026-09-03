# typed: false

# A GM may designate one of the game's pages as the environment/setting page.
# Its markdown body becomes the setting portion of an AI character-portrait
# prompt. Nullable: a game need not designate one, in which case a portrait
# prompt composes from only the safety preamble and the player's own prompt.
class AddEnvironmentPageToGames < ActiveRecord::Migration[8.1]
  def change
    add_reference :games, :environment_page, null: true, foreign_key: { to_table: :pages }
  end
end
