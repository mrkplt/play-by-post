# typed: strict

# A scene card in the Game View: just the title and a participant count, per the
# redesign (no invented "Open"/"GM" badges). Parent/child scene links are kept
# where present — real threading functionality. Unread/attention scenes glow.
class Shared::SceneCardComponent < ApplicationComponent
  extend T::Sig

  sig { params(scene: ScenePresenter, game: GamePresenter, hot: T::Boolean).void }
  def initialize(scene:, game:, hot: false)
    @scene = scene
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

  sig { returns(T::Array[ScenePresenter]) }
  def child_scenes
    @scene.child_scenes_in(@game)
  end

  sig { params(child: ScenePresenter).returns(String) }
  def path_for(child)
    helpers.game_scene_path(@game, child)
  end
end
