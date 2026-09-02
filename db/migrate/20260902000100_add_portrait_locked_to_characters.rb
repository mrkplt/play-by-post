# typed: false

# A character's portrait can be permanently locked. This is set when an AI
# portrait generation is refused by the provider's content moderation: the
# character's current portrait is forced to a static placeholder and no
# in-app actor (player or GM) may change the portrait again. There is no
# in-app unlock — recovery, if ever, is an out-of-band operator action.
class AddPortraitLockedToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :portrait_locked, :boolean, default: false, null: false
  end
end
