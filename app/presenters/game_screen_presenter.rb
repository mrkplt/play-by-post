# typed: strict

# The whole game screen (GamesController#show) as one object: the game chrome,
# the show state, the roster and the scenes panel. Each part is still its own
# presenter — this only bundles them, so the controller assigns one ivar
# instead of four and the template reaches each part by name. Wraps
# GamePresenter as its subject (composition, per the layering rule that a
# presenter's subject may be another presenter).
class GameScreenPresenter < BasePresenter
  extend T::Sig

  sig { params(model: GamePresenter, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  # Who is looking and what renders their links — the same for every panel on
  # the screen, so it travels as one thing.
  class Viewer < T::Struct
    const :current_user, User
    const :urls, T.untyped
    const :helpers, T.untyped
  end

  # Builds the game presenter's three panels together — they all take the same
  # viewer, so assembling them separately only invites them to disagree.
  sig { params(game: GamePresenter, viewer: Viewer).returns(GameScreenPresenter) }
  def self.build(game, viewer)
    user = viewer.current_user
    urls = viewer.urls

    new(
      game,
      show: GameShowPresenter.new(game, current_user: user, urls: urls, helpers: viewer.helpers),
      roster: GameRosterPresenter.new(game, current_user: user, urls: urls),
      scenes: GameScenesPanelPresenter.new(game, current_user: user)
    )
  end

  sig { returns(GamePresenter) }
  def game
    @model
  end

  sig { returns(GameShowPresenter) }
  def show
    @options.fetch(:show)
  end

  sig { returns(GameRosterPresenter) }
  def roster
    @options.fetch(:roster)
  end

  sig { returns(GameScenesPanelPresenter) }
  def scenes
    @options.fetch(:scenes)
  end
end
