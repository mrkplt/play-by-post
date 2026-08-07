# typed: strict

# The read view of a single game page: the markdown body rendered into a card,
# with GM-only Edit and Delete actions. Rendered below the page header on the
# Page show screen. Visibility itself is enforced by the controller/policy; this
# component only decides whether to show the GM affordances.
class Shared::PageDetailComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: Game, page: Page, is_gm: T::Boolean).void }
  def initialize(game:, page:, is_gm:)
    @game = T.let(game, Game)
    @page = T.let(page, Page)
    @is_gm = T.let(is_gm, T::Boolean)
  end

  sig { returns(Game) }
  attr_reader :game

  sig { returns(Page) }
  attr_reader :page

  sig { returns(T::Boolean) }
  def gm?
    @is_gm
  end

  sig { returns(T::Boolean) }
  def body?
    @page.body.present?
  end
end
