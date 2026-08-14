# typed: strict

class CharactersController < ApplicationController
  extend T::Sig
  include CharacterScoped

  before_action :set_game
  before_action :require_game_access!
  before_action :require_active_member_for_write!, only: %i[new create edit update]
  before_action :set_character, only: %i[show edit update archive restore]
  before_action :require_visible!, only: %i[show edit update archive restore]
  before_action :require_edit_access!, only: %i[edit update]
  after_action :verify_authorized

  sig { void }
  def new
    character = game.characters.new
    authorize character
    assign_presenters(character)
  end

  sig { void }
  def create
    character = game.characters.new
    authorize character

    if CharacterCreation.new(character, policy(character), params).call(current_user)
      redirect_to game_character_path(game, character), notice: "Character created."
    else
      assign_presenters(character)
      render :new, status: :unprocessable_content
    end
  end

  sig { void }
  def show
    authorize character
    @versions = T.let(presenter_builder.versions(character), T.nilable(T::Array[CharacterVersionPresenter]))
    @character_owner = T.let(UserPresenter.new(character.user), T.nilable(UserPresenter))
    assign_presenters(character)
  end

  sig { void }
  def edit
    authorize character
    assign_presenters(character)
  end

  sig { void }
  def archive
    authorize character
    character.archive!
    redirect_to game_character_path(game, character), notice: "#{character.name} archived."
  end

  sig { void }
  def restore
    authorize character
    character.update!(archived_at: nil)
    redirect_to game_character_path(game, character), notice: "#{character.name} restored."
  end

  sig { void }
  def update
    authorize character
    if character.update(permitted_attributes(character))
      redirect_to game_character_path(game, character), notice: "Character updated."
    else
      assign_presenters(character)
      render :edit, status: :unprocessable_content
    end
  end

  private

  # Populates the game/character presenter pair every read/error render needs.
  sig { params(character: Character).void }
  def assign_presenters(character)
    @game_presenter = T.let(presenter_builder.game_presenter, T.nilable(GamePresenter))
    @character_presenter = T.let(
      presenter_builder.character_presenter(character, policy(character)), T.nilable(CharacterPresenter)
    )
  end

  sig { returns(CharacterPresenterBuilder) }
  def presenter_builder
    CharacterPresenterBuilder.new(game, policy(game))
  end

  sig { void }
  def require_game_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(game).view?
  end

  sig { void }
  def require_visible!
    redirect_to game_path(game), alert: "That character sheet is hidden." unless policy(character).visible?
  end

  sig { void }
  def require_edit_access!
    redirect_to game_character_path(game, character), alert: "You cannot edit this character." unless policy(character).update?
  end

  sig { void }
  def require_active_member_for_write!
    require_active_member!(game)
  end
end
