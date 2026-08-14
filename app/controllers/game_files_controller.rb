# typed: strict

class GameFilesController < ApplicationController
  extend T::Sig

  before_action :set_game
  before_action :require_game_access!
  after_action :verify_authorized, except: :index

  sig { void }
  def index
    @game_file_collection = T.let(
      GameFileCollectionPresenter.new(files_for(T.must(@game))), T.nilable(GameFileCollectionPresenter)
    )
    @game_presenter = T.let(GamePresenter.new(T.must(@game), policy: policy(@game)), T.nilable(GamePresenter))
    @game_file_presenter = T.let(
      GameFilePresenter.new(T.must(@game).game_files.new), T.nilable(GameFilePresenter)
    )
  end

  sig { void }
  def create
    authorize T.must(@game).game_files.new
    uploaded_file = params.dig(:game_file, :file)
    unless uploaded_file
      redirect_to game_game_files_path(@game), alert: "Please select a file to upload."
      return
    end

    game_file = T.must(@game).game_files.new(filename: uploaded_file.original_filename)
    AttachmentUploader.attach(
      attachment: game_file.file,
      attachable: uploaded_file,
      kind: "game_file",
      user: current_user,
      game: @game,
      original_filename: uploaded_file.original_filename
    )

    if game_file.save
      redirect_to game_game_files_path(@game), notice: "File uploaded."
    else
      @game_file_collection = T.let(
        GameFileCollectionPresenter.new(files_for(T.must(@game))), T.nilable(GameFileCollectionPresenter)
      )
      @game_presenter = T.let(GamePresenter.new(T.must(@game), policy: policy(@game)), T.nilable(GamePresenter))
      @game_file_presenter = T.let(GameFilePresenter.new(game_file), T.nilable(GameFilePresenter))
      render :index, status: :unprocessable_content
    end
  end

  # Authorization runs before the lookup, and deliberately: deciding it against
  # an unsaved instance keeps the answer independent of whether the id exists,
  # so an unauthorized caller cannot tell a missing file from a forbidden one.
  sig { void }
  def destroy
    files = T.must(@game).game_files
    authorize files.new
    files.find(params[:id]).destroy
    redirect_to game_game_files_path(@game), notice: "File deleted."
  end

  private

  sig { void }
  def set_game
    @game = T.let(Game.find(params[:game_id]), T.nilable(Game))
  end

  sig { void }
  def require_game_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(@game).view?
  end

  sig { params(game: Game).returns(ActiveRecord::Relation) }
  def files_for(game)
    game.game_files.includes(file_attachment: :blob).order(created_at: :desc)
  end
end
