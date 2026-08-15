# typed: strict

# The New Entry / Edit Entry full-page form for a Campaign Notebook entry: a
# title field and a markdown body editor (formatting toolbar + live preview),
# mirroring Shared::PageFormComponent. The component derives its rendering
# mode (new vs edit), labels, and back-href from the entry it is handed.
class Shared::NotebookFormComponent < ApplicationComponent
  extend T::Sig
  include Shared::RecordBackedForm

  sig { params(game: GamePresenter, notebook_entry: NotebookEntryPresenter).void }
  def initialize(game:, notebook_entry:)
    @game = T.let(game, GamePresenter)
    @notebook_entry = T.let(notebook_entry, NotebookEntryPresenter)
  end

  sig { returns(GamePresenter) }
  attr_reader :game

  sig { returns(NotebookEntryPresenter) }
  attr_reader :notebook_entry

  sig { override.returns(NotebookEntryPresenter) }
  def record
    @notebook_entry
  end

  sig { returns(String) }
  def submit_label
    new_record? ? "Create Entry" : "Save"
  end

  # There is no read screen for an entry, so leaving the form always returns
  # to the board.
  sig { returns(String) }
  def back_href
    helpers.game_notebook_entries_path(@game)
  end

  sig { returns(String) }
  def form_id
    new_record? ? "notebook_entry_new_form_element" : "notebook_entry_#{@notebook_entry.id}_edit_form_element"
  end
end
