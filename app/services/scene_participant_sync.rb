# typed: strict
# frozen_string_literal: true

# Reconciles a scene's participant rows against a newly-selected character
# set (the Edit Participants form's "which characters are in this scene"
# submission): drop player rows no longer selected (the GM row is exempt),
# guarantee the GM row exists, then upsert each selected character's row.
# Extracted from SceneParticipantsController to keep the controller under
# the project's file-length ceiling — this is model-adjacent write logic,
# not a per-request concern.
class SceneParticipantSync
  extend T::Sig

  sig { params(scene: Scene, characters: T::Enumerable[Character]).void }
  def self.call(scene:, characters:)
    new(scene, characters).call
  end

  sig { params(scene: Scene, characters: T::Enumerable[Character]).void }
  def initialize(scene, characters)
    @scene = scene
    @characters = characters
  end

  sig { void }
  def call
    gm_id = T.must(T.must(@scene.game).game_master).id
    prune_stale_participants(gm_id)
    @scene.scene_participants.find_or_create_by!(user_id: gm_id)
    upsert_character_participants
  end

  private

  sig { params(gm_id: Integer).void }
  def prune_stale_participants(gm_id)
    @scene.scene_participants
      .where.not(user_id: gm_id)
      .where.not(user_id: @characters.map(&:user_id))
      .destroy_all
  end

  sig { void }
  def upsert_character_participants
    @characters.each do |character|
      @scene.scene_participants
        .find_or_initialize_by(user_id: character.user_id)
        .update!(character: character)
    end
  end
end
