# typed: strict

# Bundles the game screen's presenters so the controller assigns one ivar
# instead of four. Wraps GamePresenter as its subject; the panels are options.
class GameScreenPresenter < BasePresenter
  extend T::Sig

  sig { params(model: GamePresenter, options: T.untyped).void }
  def initialize(model, **options)
    super
  end

  class Viewer < T::Struct
    const :current_user, User
    const :urls, T.untyped
    const :helpers, T.untyped
  end

  # Built together so the panels cannot disagree about the viewer.
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
