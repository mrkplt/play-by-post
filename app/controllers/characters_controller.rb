# typed: strict

class CharactersController < ApplicationController
  extend T::Sig

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
    @game_presenter = T.let(game_presenter, T.nilable(GamePresenter))
    @character_presenter = T.let(character_presenter(character), T.nilable(CharacterPresenter))
  end

  sig { void }
  def create
    character = game.characters.new
    authorize character
    @game_presenter = T.let(game_presenter, T.nilable(GamePresenter))

    if policy(character).assign_owner?
      if params[:character][:user_id].blank?
        character.errors.add(:base, "Please select a player")
        @character_presenter = T.let(character_presenter(character), T.nilable(CharacterPresenter))
        return render :new, status: :unprocessable_content
      end
      owner = User.find(params[:character][:user_id])
    else
      owner = current_user
    end

    character.assign_attributes(permitted_attributes(character))
    character.user = owner

    if character.save
      redirect_to game_character_path(game, character), notice: "Character created."
    else
      @character_presenter = T.let(character_presenter(character), T.nilable(CharacterPresenter))
      render :new, status: :unprocessable_content
    end
  end

  sig { void }
  def show
    authorize character
    @versions = T.let(
      character.character_versions.order(created_at: :desc).includes(:edited_by)
        .map { |version| CharacterVersionPresenter.new(version) },
      T.nilable(T::Array[CharacterVersionPresenter])
    )
    @character_owner = T.let(UserPresenter.new(character.user), T.nilable(UserPresenter))
    @game_presenter = T.let(game_presenter, T.nilable(GamePresenter))
    @character_presenter = T.let(character_presenter(character), T.nilable(CharacterPresenter))
  end

  sig { void }
  def edit
    authorize character
    @game_presenter = T.let(game_presenter, T.nilable(GamePresenter))
    @character_presenter = T.let(character_presenter(character), T.nilable(CharacterPresenter))
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
      @game_presenter = T.let(game_presenter, T.nilable(GamePresenter))
      @character_presenter = T.let(character_presenter(character), T.nilable(CharacterPresenter))
      render :edit, status: :unprocessable_content
    end
  end

  private

  sig { void }
  def set_game
    @game = T.let(Game.find(params[:game_id]), T.nilable(Game))
  end

  sig { void }
  def set_character
    @character = T.let(game.characters.find(params[:id]), T.nilable(Character))
  end

  sig { returns(Game) }
  def game
    T.must(@game)
  end

  sig { returns(Character) }
  def character
    T.must(@character)
  end

  sig { returns(T::Array[User]) }
  def players_for_select
    game.active_members.where(role: "player").includes(:user).map(&:user)
  end

  sig { void }
  def require_game_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(game).view?
  end

  # The hidden-sheet gate: a hidden sheet is visible only to its owner or the GM.
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

  sig { params(character: Character).returns(CharacterPresenter) }
  def character_presenter(character)
    CharacterPresenter.new(
      character,
      game_policy: policy(game),
      character_policy: policy(character),
      players: players_for_select
    )
  end

  sig { returns(GamePresenter) }
  def game_presenter
    GamePresenter.new(game, policy: policy(game))
  end
end
