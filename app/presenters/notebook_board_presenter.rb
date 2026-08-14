# typed: strict

# View model for a game's Campaign Notebook board: the kanban of entries the
# GM works, grouped by lane. Owns the grouping query so no view, controller or
# component groups NotebookEntry rows by status itself — that grouping is a
# join a presenter does, not a hash the view builds.
class NotebookBoardPresenter < BasePresenter
  extend T::Sig

  sig { params(model: Game, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(T::Hash[String, T::Array[NotebookEntryPresenter]]) }
  def entries_by_status
    @entries_by_status ||= T.let(
      @model.notebook_entries.order(:created_at).to_a
        .group_by(&:status)
        .transform_values { |entries| entries.map { |entry| NotebookEntryPresenter.new(entry) } },
      T.nilable(T::Hash[String, T::Array[NotebookEntryPresenter]])
    )
  end

  sig { params(status: String).returns(T::Array[NotebookEntryPresenter]) }
  def entries_for(status)
    entries_by_status.fetch(status, [])
  end
end
