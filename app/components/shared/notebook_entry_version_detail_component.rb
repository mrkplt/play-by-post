# typed: strict

# The read view of a single historical notebook entry version: the version's
# timestamp and editor, then its title and body rendered into a card. Keeps the
# styled markup out of the notebook_entry_versions/show template. Mirrors
# Shared::PageVersionDetailComponent.
class Shared::NotebookEntryVersionDetailComponent < ApplicationComponent
  extend T::Sig

  sig { params(version: NotebookEntryVersionPresenter).void }
  def initialize(version:)
    @version = T.let(version, NotebookEntryVersionPresenter)
  end

  sig { returns(NotebookEntryVersionPresenter) }
  attr_reader :version
end
