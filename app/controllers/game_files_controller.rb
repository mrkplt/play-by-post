# typed: true

class GameFilesController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :require_game_access!
  before_action :require_gm!, only: %i[create destroy]

  sig { void }
  def index
    @game_files = @game.game_files.includes(file_attachment: :blob).order(created_at: :desc)
    @is_gm = @game.game_master?(current_user)
  end

  sig { void }
  def create
    uploaded_file = params.dig(:game_file, :file)
    unless uploaded_file
      redirect_to game_game_files_path(@game), alert: "Please select a file to upload."
      return
    end

    @game_file = @game.game_files.new(filename: uploaded_file.original_filename)
    @game_file.file.attach(uploaded_file)

    if @game_file.save
      redirect_to game_game_files_path(@game), notice: "File uploaded."
    else
      @game_files = @game.game_files.includes(file_attachment: :blob).order(created_at: :desc)
      @is_gm = @game.game_master?(current_user)
      render :index, status: :unprocessable_content
    end
  end

  sig { void }
  def destroy
    @game.game_files.find(params[:id]).destroy
    redirect_to game_game_files_path(@game), notice: "File deleted."
  end

  private

  sig { void }
  def set_game
    @game = Game.find(params[:game_id])
  end

  sig { void }
  def require_game_access!
    membership = @game.member_for(current_user)
    return if membership&.game_master?
    return if membership&.active? || membership&.removed?

    redirect_to root_path, alert: "You do not have access to this game."
  end

  sig { void }
  def require_gm!
    unless @game.game_master?(current_user)
      redirect_to game_path(@game), alert: "Only the GM can manage files."
    end
  end
end
