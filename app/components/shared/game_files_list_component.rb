# typed: strict

# The Files page list: the game's files newest-first in a gallery, or an empty
# state. Wrapped in a stable id so GameFilesController re-renders it in place
# after an upload or delete. Takes presentation-ready GameFilePresenter rows.
class Shared::GameFilesListComponent < ApplicationComponent
  extend T::Sig

  # The stable wrapper id the page renders and the in-place update targets.
  DOM_ID = "game_files_list"

  EMPTY = "No files uploaded yet."

  sig { params(game_files: T::Array[GameFilePresenter]).void }
  def initialize(game_files:)
    @game_files = game_files
  end

  sig { returns(T::Array[GameFilePresenter]) }
  attr_reader :game_files

  sig { returns(T::Boolean) }
  def any?
    game_files.any?
  end
end
