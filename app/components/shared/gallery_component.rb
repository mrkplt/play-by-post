# typed: strict

# The Files tab's thumbnail grid plus its lightbox modal. Each file's
# download/delete URLs and thumbnail/lightbox markup are already resolved on
# its GameFilePresenter (built with game/helpers/can_manage at construction),
# so the component only lays out what it is handed. Whether the delete
# affordance shows is derived from the files themselves — a manager's files
# already carry a `delete_url`, so a caller-supplied `can_manage` flag would
# just be re-stating a fact the presenters already encode.
class Shared::GalleryComponent < ApplicationComponent
  extend T::Sig

  sig { params(game_files: T::Array[GameFilePresenter]).void }
  def initialize(game_files:)
    @game_files = T.let(game_files, T::Array[GameFilePresenter])
  end

  sig { returns(T::Array[GameFilePresenter]) }
  attr_reader :game_files

  sig { returns(T::Boolean) }
  def can_manage?
    game_files.any? { |gf| gf.delete_url.present? }
  end
end
