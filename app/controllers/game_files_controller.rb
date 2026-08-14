# typed: true

class GameFilesController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :require_game_access!
  after_action :verify_authorized, except: :index

  sig { void }
  def index
    @game_presenter = GamePresenter.new(@game, policy: policy(@game))
    @game_files = build_game_file_presenters
    @game_file_presenter = GameFilePresenter.new(@game.game_files.new)
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
      @game_presenter = GamePresenter.new(@game, policy: policy(@game))
      @game_files = build_game_file_presenters
      @game_file_presenter = GameFilePresenter.new(@game_file)
      render :index, status: :unprocessable_content
    end
  end

  # Authorization runs before the lookup, and deliberately: deciding it against
  # an unsaved instance keeps the answer independent of whether the id exists,
  # so an unauthorized caller cannot tell a missing file from a forbidden one.
  sig { void }
  def destroy
    files = @game.game_files
    authorize files.new
    files.find(params[:id]).destroy
    redirect_to game_game_files_path(@game), notice: "File deleted."
  end

  private

  sig { returns(T::Array[GameFilePresenter]) }
  def build_game_file_presenters
    @game.game_files.includes(file_attachment: :blob).order(created_at: :desc).map do |gf|
      GameFilePresenter.new(gf, game: @game, helpers: helpers, can_manage: policy(@game).manage?)
    end
  end

  sig { void }
  def set_game
    @game = Game.find(params[:game_id])
  end

  sig { void }
  def require_game_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(@game).view?
  end
end
