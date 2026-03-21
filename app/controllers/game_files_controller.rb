class GameFilesController < ApplicationController
  before_action :set_game
  before_action :require_game_access!
  before_action :require_gm!, only: %i[create destroy]

  def index
    @game_files = @game.game_files.includes(file_attachment: :blob).order(created_at: :desc)
    @is_gm = @game.game_master?(current_user)
  end

  def create
    @game_file = @game.game_files.new(filename: params[:game_file][:file]&.original_filename)
    @game_file.file.attach(params[:game_file][:file])

    if @game_file.save
      redirect_to game_game_files_path(@game), notice: "File uploaded."
    else
      @game_files = @game.game_files.includes(file_attachment: :blob).order(created_at: :desc)
      @is_gm = @game.game_master?(current_user)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @game.game_files.find(params[:id]).destroy
    redirect_to game_game_files_path(@game), notice: "File deleted."
  end

  private

  def set_game
    @game = Game.find(params[:game_id])
  end

  def require_game_access!
    membership = @game.member_for(current_user)
    return if membership&.game_master?
    return if membership&.active? || membership&.removed?

    redirect_to root_path, alert: "You do not have access to this game."
  end

  def require_gm!
    unless @game.game_master?(current_user)
      redirect_to game_path(@game), alert: "Only the GM can manage files."
    end
  end
end
