# typed: true

class Shared::PostComposerComponent < ApplicationComponent
  extend T::Sig

  sig { params(post: Post, game: Game, scene: Scene, draft: T.nilable(Post)).void }
  def initialize(post:, game:, scene:, draft: nil)
    @post  = post
    @game  = game
    @scene = scene
    @draft = draft
  end
end
