# typed: strict

class Shared::FileUploadFormComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: Game, game_file: T.nilable(GameFile)).void }
  # mutant:disable
  def initialize(game:, game_file: nil)
    @game = T.let(game, Game)
    @game_file = T.let(game_file, T.nilable(GameFile))
  end

  sig { returns(T::Boolean) }
  def error?
    @game_file&.errors&.any? || false
  end

  sig { returns(T.nilable(String)) }
  def error_message
    return unless @game_file

    @game_file.errors[:file].first || @game_file.errors.full_messages.first
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
