# typed: strict

class Shared::PostComposerComponent < ApplicationComponent
  extend T::Sig

  sig do
    params(
      post: PostPresenter, game: GamePresenter, scene: ScenePresenter,
      draft: T.nilable(PostPresenter)
    ).void
  end
  def initialize(post:, game:, scene:, draft: nil)
    @post  = post
    @game  = game
    @scene = scene
    @draft = draft
  end
end
