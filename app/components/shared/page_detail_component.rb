# typed: strict

# The read view of a single game page: the markdown body rendered into a card,
# with GM-only Edit and Delete actions. Rendered below the page header on the
# Page show screen. Visibility itself is enforced by the controller/policy; this
# component only decides whether to show the GM affordances.
class Shared::PageDetailComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: GamePresenter, page: PagePresenter, can_manage: T::Boolean).void }
  def initialize(game:, page:, can_manage:)
    @game = T.let(game, GamePresenter)
    @page = T.let(page, PagePresenter)
    @can_manage = T.let(can_manage, T::Boolean)
  end

  sig { returns(GamePresenter) }
  attr_reader :game

  sig { returns(PagePresenter) }
  attr_reader :page

  sig { returns(T.nilable(String)) }
  def title
    @page.title
  end

  sig { returns(T::Boolean) }
  def can_manage?
    @can_manage
  end

  sig { returns(T::Boolean) }
  def body?
    @page.body?
  end

  sig { returns(String) }
  def body
    @page.body
  end
end
