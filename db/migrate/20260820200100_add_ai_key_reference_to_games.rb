# typed: false

# Same seam as users (see AddAiKeyReferenceToUsers): an opaque handle into the
# separate encrypted key store, not key material. A game-level BYOK key is the
# fallback funding source when the acting player has none of their own — see
# AiKeyResolver.
class AddAiKeyReferenceToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :ai_key_reference, :string
  end
end
