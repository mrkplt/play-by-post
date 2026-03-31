# typed: true

class Shared::PostComposerComponent < ApplicationComponent
  extend T::Sig

  sig { params(post: Post, game: Game, scene: Scene).void }
  def initialize(post:, game:, scene:)
    @post  = post
    @game  = game
    @scene = scene
  end
end
