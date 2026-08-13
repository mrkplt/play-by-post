# typed: true

class GameFilesController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :require_game_access!
  after_action :verify_authorized, except: :index

  sig { void }
  def index
    @game_files = @game.game_files.includes(file_attachment: :blob).order(created_at: :desc)
    @game_presenter = GamePresenter.new(@game, current_user)
    @game_file = @game.game_files.new
  end

  sig { void }
  def create
    authorize @game.game_files.new
    uploaded_file = params.dig(:game_file, :file)
    unless uploaded_file
      redirect_to game_game_files_path(@game), alert: "Please select a file to upload."
      return
    end

    @game_file = @game.game_files.new(filename: uploaded_file.original_filename)
    AttachmentUploader.attach(
      attachment: @game_file.file,
      attachable: uploaded_file,
      kind: "game_file",
      user: current_user,
      game: @game,
      original_filename: uploaded_file.original_filename
    )

    if @game_file.save
      redirect_to game_game_files_path(@game), notice: "File uploaded."
    else
      @game_files = @game.game_files.includes(file_attachment: :blob).order(created_at: :desc)
      @game_presenter = GamePresenter.new(@game, current_user)
      render :index, status: :unprocessable_content
    end
  end

  sig { void }
  def destroy
    authorize @game.game_files.new
    game_file = @game.game_files.find(params[:id])
    game_file.destroy
    redirect_to game_game_files_path(@game), notice: "File deleted."
  end

  private

  sig { void }
  def set_game
    @game = Game.find(params[:game_id])
  end

  sig { void }
  def require_game_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(@game).view?
  end
end
