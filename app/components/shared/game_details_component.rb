# typed: strict

# The "Game Details" section on the Game Settings screen: the game name with a
# GM-only Edit link, and the description rendered as markdown (single newlines
# become line breaks) — or a "No description yet." placeholder when the GM has
# not written one. GM-only; the caller gates rendering on the GM check.
class Shared::GameDetailsComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: Game).void }
  def initialize(game:)
    @game = T.let(game, Game)
  end

  sig { returns(String) }
  def name
    @game.name
  end

  sig { returns(T::Boolean) }
  def description?
    @game.description.present?
  end

  sig { returns(String) }
  def rendered_description
    MarkdownRenderer.render(@game.description)
  end

  sig { returns(String) }
  def edit_path
    helpers.edit_game_path(@game)
  end
end
