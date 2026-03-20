class SceneParticipant < ApplicationRecord
  belongs_to :scene
  belongs_to :user
  belongs_to :character, optional: true

  # Characters are the primary actor; GM rows have no character so fall back to display name.
  def display_name
    character&.name || user.display_name || user.email
  end
end
