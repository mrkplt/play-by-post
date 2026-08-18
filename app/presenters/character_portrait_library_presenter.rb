# typed: strict

# The character-portrait flavour of ImageLibraryPresenter: the character's
# image library, manageable only by the owning player (CharacterImagePolicy),
# with the nested game/character image routes.
class CharacterPortraitLibraryPresenter < ImageLibraryPresenter
  extend T::Sig

  sig do
    params(
      character: Character,
      game: Game,
      can_manage: T::Boolean,
      helpers: T.untyped
    ).void
  end
  def initialize(character:, game:, can_manage:, helpers:)
    @character = character
    @game = game
    @can_manage = can_manage
    super(helpers: helpers)
  end

  sig { override.returns(T::Boolean) }
  def can_manage?
    @can_manage
  end

  sig { override.returns(String) }
  def upload_url
    @helpers.game_character_images_path(@game, @character)
  end

  private

  sig { override.returns(T.untyped) }
  def images
    @character.character_images.with_attached_file.order(created_at: :desc)
  end

  sig { override.params(image: T.untyped).returns(String) }
  def set_current_url(image)
    @helpers.game_character_image_path(@game, @character, image)
  end

  sig { override.params(image: T.untyped).returns(String) }
  def delete_url(image)
    @helpers.game_character_image_path(@game, @character, image)
  end
end
