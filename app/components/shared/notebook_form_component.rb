# typed: strict

# The New Entry / Edit Entry full-page form for a Campaign Notebook entry: a
# title field and a markdown body editor (formatting toolbar + live preview),
# mirroring Shared::PageFormComponent. The component derives its rendering
# mode (new vs edit), labels, and back-href from the entry it is handed.
class Shared::NotebookFormComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: Game, notebook_entry: NotebookEntry).void }
  def initialize(game:, notebook_entry:)
    @game = T.let(game, Game)
    @notebook_entry = T.let(notebook_entry, NotebookEntry)
  end

  sig { returns(Game) }
  attr_reader :game

  sig { returns(NotebookEntry) }
  attr_reader :notebook_entry

  sig { returns(T::Boolean) }
  def new_record?
    @notebook_entry.new_record?
  end

  sig { returns(String) }
  def submit_label
    new_record? ? "Create Entry" : "Save"
  end

  sig { returns(String) }
  def back_href
    new_record? ? helpers.game_notebook_entries_path(@game) : helpers.game_notebook_entry_path(@game, @notebook_entry)
  end

  sig { returns(T::Boolean) }
  def errors?
    @notebook_entry.errors.any?
  end

  sig { returns(T::Array[String]) }
  def error_messages
    @notebook_entry.errors.full_messages
  end
end
