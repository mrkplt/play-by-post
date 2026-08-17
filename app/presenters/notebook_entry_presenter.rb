# typed: strict

# View model for a single Campaign Notebook entry: the title/status/slug the
# board and lane components render, plus the promoted-page facts the entry's
# actions need. There is no PagePresenter yet, so the promoted page's title
# and slug are exposed directly here rather than handing components the page
# model itself — a component builds the link from these primitives.
class NotebookEntryPresenter < BasePresenter
  extend T::Sig

  sig { params(model: NotebookEntry, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(String) }
  def title
    @model.title.to_s
  end

  sig { returns(String) }
  def slug
    @model.slug.to_s
  end

  sig { returns(String) }
  def status
    @model.status.to_s
  end

  sig { returns(T.nilable(String)) }
  def status_previously_was
    @model.status_previously_was
  end

  sig { returns(T::Boolean) }
  def new_record?
    @model.new_record?
  end

  sig { returns(T.nilable(Integer)) }
  def id
    @model.id
  end

  sig { returns(T::Boolean) }
  def errors?
    @model.errors.any?
  end

  sig { returns(T::Array[String]) }
  def error_messages
    @model.errors.full_messages
  end

  sig { returns(T::Boolean) }
  def promoted?
    @model.promoted?
  end

  sig { returns(String) }
  def promoted_page_title
    @model.promoted_page.title
  end

  sig { returns(String) }
  def promoted_page_slug
    @model.promoted_page.slug.to_s
  end

  # The entry's version history, newest first, wrapped for the history component
  # on the edit screen. Owning the wrapping here keeps the controller free of the
  # model→presenter mapping.
  sig { returns(T::Array[NotebookEntryVersionPresenter]) }
  def version_history
    @model.notebook_entry_versions.order(created_at: :desc).map do |version|
      NotebookEntryVersionPresenter.new(version)
    end
  end
end
