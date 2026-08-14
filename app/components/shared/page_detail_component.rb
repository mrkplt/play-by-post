# typed: strict

# The read view of a single game page: the markdown body rendered into a card,
# with GM-only Edit and Delete actions. Rendered below the page header on the
# Page show screen. Visibility itself is enforced by the controller/policy;
# this component only decides whether to show the GM affordances, reading the
# capability off the presenter's injected policy rather than a separate flag.
class Shared::PageDetailComponent < ApplicationComponent
  extend T::Sig

  sig { params(page: PagePresenter).void }
  def initialize(page:)
    @page = T.let(page, PagePresenter)
  end

  sig { returns(Game) }
  def game
    page.game
  end

  sig { returns(PagePresenter) }
  attr_reader :page

  sig { returns(String) }
  def title
    page.title
  end

  sig { returns(T::Boolean) }
  def can_manage?
    page.can_manage?
  end

  sig { returns(T::Boolean) }
  def body?
    page.body?
  end

  sig { returns(String) }
  def body
    page.body
  end
end
