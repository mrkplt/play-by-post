# typed: strict

# A scene card in the Game View: just the title and a participant count, per the
# redesign (no invented "Open"/"GM" badges). Parent/child scene links are kept
# where present — real threading functionality. Unread/attention scenes glow.
class Shared::SceneCardComponent < ApplicationComponent
  extend T::Sig

  sig { params(scene: ScenePresenter, game: GamePresenter, hot: T::Boolean).void }
  def initialize(scene:, game:, hot: false)
    @scene = scene
    @card = T.let(SceneCardPresenter.new(scene), SceneCardPresenter)
    @game = game
    @hot = hot
  end

  sig { returns(T::Boolean) }
  def hot?
    @hot
  end

  sig { returns(String) }
  def scene_path
    helpers.game_scene_path(@game, @scene)
  end

  sig { returns(T::Boolean) }
  def parent_scene?
    @card.parent_scene?
  end

  sig { returns(ScenePresenter) }
  def parent_scene_presenter
    @card.parent_scene_presenter
  end

  sig { returns(T::Array[ScenePresenter]) }
  def child_scenes
    @card.child_scenes_in(@game)
  end

  sig { params(child: ScenePresenter).returns(String) }
  def path_for(child)
    helpers.game_scene_path(@game, child)
  end
end
