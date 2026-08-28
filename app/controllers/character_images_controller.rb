# typed: strict

# A character's portrait library, nested under the game's character. The CRUD
# lives in ImageLibrary; this controller supplies the character-owned hooks and
# the game/character lookup. Authorization is CharacterImagePolicy#manage? —
# the owning player only (the GM does not curate a player's portraits).
class CharacterImagesController < ApplicationController
  extend T::Sig
  include RequestMemo
  include ImageLibrary

  before_action :require_game_access!
  after_action :verify_authorized

  private

  sig { override.returns(T.untyped) }
  def image_collection
    character.character_images
  end

  sig { override.returns(String) }
  def image_kind
    "character_image"
  end

  sig { override.returns(T.nilable(Game)) }
  def image_game
    game
  end

  # The portrait library exactly as characters/show renders it, for the in-place
  # swap. Every action reaching here has already `authorize`d the manage
  # capability (it raises otherwise), so the acting user can manage this library
  # by construction — can_manage is true without re-asking the policy.
  sig { override.returns(Shared::ImageLibraryComponent) }
  def rendered_library
    library = CharacterPortraitLibraryPresenter.new(
      character: character, game: game, can_manage: true, helpers: helpers
    )
    Shared::ImageLibraryComponent.new(
      title: "Portraits", images: library.items, can_manage: true, empty_text: "No portraits yet."
    )
  end

  # Looked up on demand and memoized through RequestMemo rather than an ivar:
  # Rails copies controller ivars into the view, so a raw-model @game/@character
  # would trip bin/check-view-layering even though these actions only redirect.
  sig { returns(Game) }
  def game
    memo(:game) { Game.find_by!(slug: params[:game_id]) }
  end

  sig { returns(Character) }
  def character
    memo(:character) { game.characters.find(params[:character_id]) }
  end

  sig { void }
  def require_game_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(game).view?
  end
end
