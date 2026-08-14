# typed: strict

# View model for a single Campaign Notebook entry's new/edit form.
class NotebookEntryPresenter < BasePresenter
  extend T::Sig

  sig { params(model: NotebookEntry, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(T::Boolean) }
  # mutant:disable
  def new_record?
    @model.new_record?
  end

  sig { returns(T::Boolean) }
  # mutant:disable
  def persisted?
    @model.persisted?
  end

  sig { returns(T.nilable(Integer)) }
  # mutant:disable
  def id
    @model.id
  end

  sig { returns(T.untyped) }
  # mutant:disable
  def title
    @model.title
  end

  sig { returns(ActiveModel::Errors) }
  # mutant:disable
  def errors
    @model.errors
  end
end
