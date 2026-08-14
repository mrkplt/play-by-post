# typed: true

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
    @character = @game.characters.new
    authorize @character
    @character_presenter = character_presenter
  end

  sig { void }
  def create
    @character = @game.characters.new
    authorize @character

    if policy(@character).assign_owner?
      if params[:character][:user_id].blank?
        @character.errors.add(:base, "Please select a player")
        @character_presenter = character_presenter
        return render :new, status: :unprocessable_content
      end
      owner = User.find(params[:character][:user_id])
    else
      owner = current_user
    end

    @character.assign_attributes(permitted_attributes(@character))
    @character.user = owner

    if @character.save
      redirect_to game_character_path(@game, @character), notice: "Character created."
    else
      @character_presenter = character_presenter
      render :new, status: :unprocessable_content
    end
  end

  sig { void }
  def show
    authorize @character
    @versions = @character.character_versions.order(created_at: :desc).includes(:edited_by)
      .map { |version| CharacterVersionPresenter.new(version) }
    @character_owner = UserPresenter.new(@character.user)
    @character_presenter = character_presenter
  end

  sig { void }
  def edit
    authorize @character
    @character_presenter = character_presenter
  end

  sig { void }
  def archive
    authorize @character
    @character.archive!
    redirect_to game_character_path(@game, @character), notice: "#{@character.name} archived."
  end

  sig { void }
  def restore
    authorize @character
    @character.update!(archived_at: nil)
    redirect_to game_character_path(@game, @character), notice: "#{@character.name} restored."
  end

  sig { void }
  def update
    authorize @character
    if @character.update(permitted_attributes(@character))
      redirect_to game_character_path(@game, @character), notice: "Character updated."
    else
      @character_presenter = character_presenter
      render :edit, status: :unprocessable_content
    end
  end

  private

  sig { void }
  def set_game
    @game = Game.find(params[:game_id])
  end

  sig { void }
  def set_character
    @character = @game.characters.find(params[:id])
  end

  sig { returns(T::Array[User]) }
  def players_for_select
    @game.active_members.where(role: "player").includes(:user).map(&:user)
  end

  sig { void }
  def require_game_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(@game).view?
  end

  # The hidden-sheet gate: a hidden sheet is visible only to its owner or the GM.
  sig { void }
  def require_visible!
    redirect_to game_path(@game), alert: "That character sheet is hidden." unless policy(@character).visible?
  end

  sig { void }
  def require_edit_access!
    redirect_to game_character_path(@game, @character), alert: "You cannot edit this character." unless policy(@character).update?
  end

  sig { void }
  def require_active_member_for_write!
    require_active_member!(@game)
  end

  sig { returns(CharacterPresenter) }
  def character_presenter
    CharacterPresenter.new(
      @character,
      game_policy: policy(@game),
      character_policy: policy(@character),
      players: players_for_select
    )
  end
end
