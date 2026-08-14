# typed: strict

# The routes a game's chrome links to, resolved here so no template builds one
# itself. Wraps a GamePresenter — composition, not duplication — and takes the
# constructing controller as `urls:`, which carries every named route helper.
#
# Split out of GamePresenter to keep that class under the project's method and
# file-length ceilings: route resolution is a distinct concern from the game's
# own display values.
class GameRoutesPresenter < BasePresenter
  extend T::Sig

  sig { params(model: GamePresenter, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  # The All Scenes screen's "New Scene" link.
  sig { returns(String) }
  def new_scene_path
    urls.new_game_scene_path(game)
  end

  # The Campaign Log's "Edit Game" link, for a GM who can manage this game.
  sig { returns(String) }
  def edit_path
    urls.edit_game_path(game)
  end

  # The Campaign Notebook board — the notebook form screens' Cancel target.
  sig { returns(String) }
  def notebook_board_href
    urls.game_notebook_entries_path(game)
  end

  private

  sig { returns(Game) }
  def game
    @model.model
  end

  sig { returns(T.untyped) }
  def urls
    @options.fetch(:urls)
  end
end
