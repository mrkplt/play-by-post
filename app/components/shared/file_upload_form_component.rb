# typed: strict

class Shared::FileUploadFormComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: GamePresenter, game_file: T.nilable(GameFilePresenter)).void }
  # mutant:disable
  def initialize(game:, game_file: nil)
    @game = T.let(game, GamePresenter)
    @game_file = T.let(game_file, T.nilable(GameFilePresenter))
  end

  sig { returns(T::Boolean) }
  def error?
    @game_file&.error? || false
  end

  sig { returns(T.nilable(String)) }
  def error_message
    @game_file&.error_message
  end

  sig { returns(Integer) }
  def max_bytes
    GameFile::MAX_SIZE
  end

  sig { returns(Integer) }
  def max_megabytes
    GameFile::MAX_SIZE / 1.megabyte
  end

  sig { returns(String) }
  def upload_url
    helpers.game_game_files_path(@game)
  end
end
