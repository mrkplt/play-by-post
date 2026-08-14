# typed: strict

# View model for the Campaign Notebook index: a game's notebook entries,
# grouped by kanban lane. Wraps the array the controller loads so the view
# never groups raw NotebookEntry records itself — "which lane does this
# belong to" is the board's display logic, not a template concern.
class NotebookBoardPresenter < BasePresenter
  extend T::Sig

  sig { params(model: T::Array[NotebookEntry], options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  # Shared::NotebookBoardComponent's own contract (T::Hash[String,
  # T::Array[NotebookEntry]]) is unchanged here — grouping the raw entries by
  # status is exactly the display-logic decision this presenter owns.
  sig { returns(T::Hash[String, T::Array[NotebookEntry]]) }
  def entries_by_status
    @model.group_by(&:status)
  end
end
