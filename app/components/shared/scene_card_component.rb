# typed: true

class Shared::SceneCardComponent < ApplicationComponent
  extend T::Sig

  sig { params(scene: ScenePresenter, game: Game).void }
  def initialize(scene:, game:)
    @scene = scene
    @game = game
  end
end
