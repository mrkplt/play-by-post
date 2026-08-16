# typed: strict

class GameFilesController < ApplicationController
  extend T::Sig

  before_action :require_game_access!
  after_action :verify_authorized, except: :index

  sig { void }
  def index
    assign_index_presenters(game.game_files.new)
  end

  sig { void }
  def create
    authorize game.game_files.new
    uploaded_file = params.dig(:game_file, :file)
    return redirect_to index_path, alert: "Please select a file to upload." unless uploaded_file

    save_uploaded_game_file(uploaded_file)
  end

  # Authorization runs before the lookup, and deliberately: deciding it against
  # an unsaved instance keeps the answer independent of whether the id exists,
  # so an unauthorized caller cannot tell a missing file from a forbidden one.
  sig { void }
  def destroy
    files = game.game_files
    authorize files.new
    files.find(params[:id]).destroy
    redirect_to index_path, notice: "File deleted."
  end

  private

  # The Files index's presenter trio, shared by #index and #create's re-render
  # on a failed upload — kept as one method so the two call sites can't drift.
  sig { params(game_file_record: GameFile).void }
  def assign_index_presenters(game_file_record)
    @game_presenter = T.let(GamePresenter.new(game, policy: policy(game)), T.nilable(GamePresenter))
    @game_files = T.let(build_game_file_presenters, T.nilable(T::Array[GameFilePresenter]))
    @game_file_presenter = T.let(GameFilePresenter.new(game_file_record), T.nilable(GameFilePresenter))
  end

  sig { params(uploaded_file: T.untyped).void }
  def save_uploaded_game_file(uploaded_file)
    game_file = build_uploaded_game_file(uploaded_file)

    if game_file.save
      redirect_to index_path, notice: "File uploaded."
    else
      assign_index_presenters(game_file)
      render :index, status: :unprocessable_content
    end
  end

  sig { params(uploaded_file: T.untyped).returns(GameFile) }
  def build_uploaded_game_file(uploaded_file)
    original_filename = uploaded_file.original_filename
    game_file = game.game_files.new(filename: original_filename)
    AttachmentUploader.attach(
      attachment: game_file.file,
      attachable: uploaded_file,
      context: AttachmentUploader::Context.build(
        kind: "game_file",
        owner: AttachmentUploader::Owner.build(user: current_user, game: game),
        naming: AttachmentUploader::Naming.build(original_filename: original_filename)
      )
    )
    game_file
  end

  sig { returns(String) }
  def index_path
    game_game_files_path(game)
  end

  sig { returns(T::Array[GameFilePresenter]) }
  def build_game_file_presenters
    game.game_files.includes(file_attachment: :blob).order(created_at: :desc).map do |gf|
      GameFilePresenter.new(gf, game: game, helpers: helpers, can_manage: policy(game).manage?)
    end
  end

  # Looked up on demand rather than cached in a before_action ivar: no
  # template reads it directly (only @game_presenter's output does), so
  # nothing needs it to persist as request state.
  sig { returns(Game) }
  def game
    Game.find(params[:game_id])
  end

  sig { void }
  def require_game_access!
    redirect_to root_path, alert: "You do not have access to this game." unless policy(game).view?
  end
end
