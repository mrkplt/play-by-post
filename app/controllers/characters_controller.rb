# typed: true

class CharactersController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :require_game_access!
  before_action :require_active_member_for_write!, only: %i[new create edit update]
  before_action :set_character, only: %i[show edit update archive restore]
  before_action :require_edit_access!, only: %i[edit update]
  before_action :require_gm!, only: %i[archive restore]

  sig { void }
  def new
    @character = Character.new
    @users = @game.active_members.where(role: "player").includes(:user).map(&:user)
  end

  sig { void }
  def create
    if @game.game_master?(current_user)
      if params[:character][:user_id].blank?
        @character = @game.characters.new
        @users = @game.active_members.where(role: "player").includes(:user).map(&:user)
        @character.errors.add(:base, "Please select a player")
        return render :new, status: :unprocessable_content
      end
      owner = User.find(params[:character][:user_id])
    else
      owner = current_user
    end

    @character = @game.characters.new(character_params.except(:user_id))
    @character.user = owner

    if @character.save
      redirect_to game_character_path(@game, @character), notice: "Character created."
    else
      @users = @game.active_members.where(role: "player").includes(:user).map(&:user)
      render :new, status: :unprocessable_content
    end
  end

  sig { void }
  def show
    @versions = @character.character_versions.order(created_at: :desc).includes(:edited_by)
    @character_owner = UserPresenter.new(@character.user)
    @version_editor_names = @versions.each_with_object({}) { |v, h| h[v.id] = UserPresenter.new(v.edited_by).display_name_or_email }
  end

  sig { void }
  def edit
  end

  sig { void }
  def archive
    @character.archive!
    redirect_to game_character_path(@game, @character), notice: "#{@character.name} archived."
  end

  sig { void }
  def restore
    @character.update!(archived_at: nil)
    redirect_to game_character_path(@game, @character), notice: "#{@character.name} restored."
  end

  sig { void }
  def update
    if @character.update(character_params.except(:user_id))
      redirect_to game_character_path(@game, @character), notice: "Character updated."
    else
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
    unless @character.editable_by?(current_user, @game) || !@character.hidden? || @game.game_master?(current_user)
      redirect_to game_path(@game), alert: "That character sheet is hidden."
    end
  end

  sig { void }
  def require_game_access!
    membership = @game.member_for(current_user)
    return if membership&.game_master?
    return if membership&.active? || membership&.removed?

    redirect_to root_path, alert: "You do not have access to this game."
  end

  sig { void }
  def require_edit_access!
    unless @character.editable_by?(current_user, @game)
      redirect_to game_character_path(@game, @character), alert: "You cannot edit this character."
    end
  end

  sig { void }
  def require_gm!
    unless @game.game_master?(current_user)
      redirect_to game_character_path(@game, @character), alert: "Only the GM can archive or restore characters."
    end
  end

  sig { void }
  def require_active_member_for_write!
    require_active_member!(@game)
  end

  sig { returns(ActionController::Parameters) }
  def character_params
    params.require(:character).permit(:name, :content, :hidden, :user_id)
  end
end
