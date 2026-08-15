# typed: strict
# frozen_string_literal: true

# Seeds a freshly created scene's participant list: the GM always joins as a
# user-only participant, and each selected character joins with the user
# derived from the character itself rather than from the form.
class SceneParticipantSeeder
  extend T::Sig

  sig { params(scene: Scene, game: Game).void }
  def initialize(scene, game)
    @scene = scene
    @game = game
  end

  # `character_ids` comes straight from params, so it is nil when the form
  # selected nobody.
  sig { params(character_ids: T.untyped).void }
  def call(character_ids)
    add_game_master
    characters_for(character_ids).each { |character| add_character(character) }
  end

  private

  sig { void }
  def add_game_master
    @scene.scene_participants.find_or_create_by!(user_id: T.must(@game.game_master).id)
  end

  sig { params(character_ids: T.untyped).returns(T::Array[Character]) }
  def characters_for(character_ids)
    ids = Array(character_ids).map(&:to_i)
    return [] if ids.empty?

    @game.characters.where(id: ids).to_a
  end

  sig { params(character: Character).void }
  def add_character(character)
    @scene.scene_participants.find_or_create_by!(user_id: character.user_id) do |participant|
      participant.character = character
    end
  end
end
