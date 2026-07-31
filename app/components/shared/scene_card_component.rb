# typed: strict

# A scene card in the Game View: just the title and a participant count, per the
# redesign (no invented "Open"/"GM" badges). Parent/child scene links are kept
# where present — real threading functionality. Unread/attention scenes glow.
class Shared::SceneCardComponent < ApplicationComponent
  extend T::Sig

  sig { params(scene: ScenePresenter, game: Game, hot: T::Boolean).void }
  def initialize(scene:, game:, hot: false)
    @scene = scene
    @game = game
    @hot = hot
  end

  sig { returns(T::Boolean) }
  def hot?
    @hot
  end
end
