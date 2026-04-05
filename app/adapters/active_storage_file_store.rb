# typed: strict

class ActiveStorageFileStore
  extend T::Sig
  include Ports::FileStore

  sig { override.params(game_file: GameFile, upload: ActionDispatch::Http::UploadedFile).void }
  def attach(game_file:, upload:)
    game_file.file.attach(upload)
  end

  sig { override.params(game_file: GameFile).void }
  def purge(game_file:)
    game_file.file.purge_later
  end
end
