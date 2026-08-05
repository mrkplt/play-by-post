# typed: strict

# The standalone "Edit Post" form, on the mobile-first component system: a
# markdown sheet editor (formatting toolbar + live preview) over the post body,
# with save/cancel actions. Post bodies render as markdown, so the editor
# offers the same formatting controls as the composer.
class Shared::PostEditFormComponent < ApplicationComponent
  extend T::Sig

  sig { params(game: Game, scene: Scene, post: Post).void }
  def initialize(game:, scene:, post:)
    @game = T.let(game, Game)
    @scene = T.let(scene, Scene)
    @post = T.let(post, Post)
  end

  sig { returns(Game) }
  attr_reader :game

  sig { returns(Scene) }
  attr_reader :scene

  sig { returns(Post) }
  attr_reader :post
end
