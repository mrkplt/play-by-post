# typed: strict

# View model for a game's wiki page row in the Pages list. `game:` and
# `urls:` (the constructing controller, which carries every named route
# helper) are supplied at construction so the presenter never builds a route
# helper of its own.
class PagePresenter < BasePresenter
  extend T::Sig

  sig { params(model: Page, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  sig { returns(String) }
  def title
    @model.title.to_s
  end

  sig { returns(String) }
  def href
    @options.fetch(:urls).game_page_path(@options.fetch(:game), @model)
  end
end
