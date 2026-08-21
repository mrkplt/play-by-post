# typed: false

# The main app db never stores key material (plaintext or ciphertext) for a
# player's BYOK OpenRouter key — that lives in a separate, worker-only
# encrypted store owned by the key-management side of the AI Control Plane
# (see AiKeyResolver::KeySource). This column is only the opaque handle that
# store resolves by: presence of a handle means "this user has a BYOK key
# configured," and its value means nothing to this app beyond that lookup.
class AddAiKeyReferenceToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :ai_key_reference, :string
  end
end
