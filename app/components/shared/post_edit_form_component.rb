# typed: strict

# The standalone "Edit Post" form, on the mobile-first component system: a
# markdown sheet editor (formatting toolbar + live preview) over the post body,
# with save/cancel actions. Post bodies render as markdown, so the editor
# offers the same formatting controls as the composer.
class Shared::PostEditFormComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: GamePresenter, scene: ScenePresenter, post: PostPresenter).void }
  def initialize(game:, scene:, post:)
    @game = T.let(game, GamePresenter)
    @scene = T.let(scene, ScenePresenter)
    @post = T.let(post, PostPresenter)
  end

  sig { returns(GamePresenter) }
  attr_reader :game

  sig { returns(ScenePresenter) }
  attr_reader :scene

  sig { returns(PostPresenter) }
  attr_reader :post

  sig { returns(String) }
  def form_id
    "edit_post_#{@post.id}_form"
  end
end
