# typed: strict

module Ports
  module FileStore
    extend T::Sig
    extend T::Helpers
    interface!

    sig { abstract.params(game_file: GameFile, upload: ActionDispatch::Http::UploadedFile).void }
    def attach(game_file:, upload:); end

    sig { abstract.params(game_file: GameFile).void }
    def purge(game_file:); end
  end
end
