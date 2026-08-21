class RemoveAiKeyReference < ActiveRecord::Migration[8.1]
  # ai_key_reference was an opaque handle column ("presence means a BYOK key
  # is configured") pointing at nothing in particular — it duplicated
  # information now derivable directly from EncryptedValue's existence
  # (EncryptedValue.exists?(owner:, value_type: "openrouter_key")). Dead now
  # that presence is checked against the real record instead of a shadow
  # column — see User#ai_key_present?/Game#ai_key_present?.
  def change
    remove_column :users, :ai_key_reference, :string
    remove_column :games, :ai_key_reference, :string
  end
end
