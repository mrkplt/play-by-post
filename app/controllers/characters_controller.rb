class CharactersController < ApplicationController
  before_action :set_game
  before_action :require_game_access!
  before_action :set_character, only: %i[show edit update]
  before_action :require_edit_access!, only: %i[edit update]

  def new
    @character = Character.new
    @users = @game.active_members.includes(:user).map(&:user)
  end

  def create
    owner = if @game.game_master?(current_user) && params[:character][:user_id].present?
      User.find(params[:character][:user_id])
    else
      current_user
    end

    @character = @game.characters.new(character_params.except(:user_id))
    @character.user = owner

    if @character.save
      redirect_to game_character_path(@game, @character), notice: "Character created."
    else
      @users = @game.active_members.includes(:user).map(&:user)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @versions = @character.character_versions.order(created_at: :desc)
  end

  def edit
  end

  def update
    if @character.update(character_params.except(:user_id))
      redirect_to game_character_path(@game, @character), notice: "Character updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_game
    @game = Game.find(params[:game_id])
  end

  def set_character
    @character = @game.characters.find(params[:id])
  end

  def require_game_access!
    membership = @game.member_for(current_user)
    return if membership&.game_master?
    return if membership&.active? || membership&.removed?

    redirect_to root_path, alert: "You do not have access to this game."
  end

  def require_edit_access!
    unless @character.editable_by?(current_user, @game)
      redirect_to game_character_path(@game, @character), alert: "You cannot edit this character."
    end
  end

  def character_params
    params.require(:character).permit(:name, :content, :active, :hidden, :user_id)
  end
end
