# typed: strict

# The read view of a single historical page version: the version's timestamp
# and editor, then its title and body rendered into a card. Keeps the styled
# markup out of the page_versions/show template.
class Shared::PageVersionDetailComponent < ApplicationComponent
  extend T::Sig

  sig { params(version: PageVersionPresenter).void }
  def initialize(version:)
    @version = T.let(version, PageVersionPresenter)
  end

  sig { returns(PageVersionPresenter) }
  attr_reader :version
end
